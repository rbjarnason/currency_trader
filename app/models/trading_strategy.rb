#TODO Make stop signals evolve

class TradingStrategy < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  DEFAULT_START_CAPITAL = 100000000.0
  DEFAULT_POSITION_UNITS = 50000.0
  FAILED_FITNESS_VALUE = -999999.0

  MINUTES_BETWEEN_POS_OPENINGS = 2.minutes

  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
  belongs_to :trading_strategy_population
  has_many   :trading_signals, :dependent => :delete_all

  # Parameters
  # 0: Time to look back in ms (10000)
  # 1: Magnitude of change since time in percent (0.01)
  # 2: Type of trading signal (Buy or Sell)
  serialize :binary_parameters, Array
  serialize :float_parameters, Array
  #serialize :simulated_trading_signals, Array

  before_save :marshall_simulated_trading_signals
  after_initialize :demarshall_simulated_trading_signals

  attr_reader :strategy_buy_short, :open_magnitude_signal_trigger, :close_magnitude_signal_trigger, :simulated_trading_signals_array, :stop_loss_pause_minutes, :stop_loss_value

  after_initialize :setup_parameters
  after_save :setup_parameters

  def check_stop_loss?
    if self.last_stop_loss_until and self.last_stop_loss_until.to_date!=Date.today
      self.last_stop_loss_until = nil
      self.save
    end
    if self.last_stop_loss_until and self.last_stop_loss_until.to_date!=Date.today
      p_and_l = TradingPosition.where(["created_at > ?",self.last_stop_loss_until]).sum("profit_loss")
    else
      p_and_l = TradingPosition.where(["DATE(created_at) = ?",Date.today]).sum("profit_loss")
    end
    if p_and_l<-(@stop_loss_value)
      self.current_stop_loss_until = DateTime.now+(@stop_loss_pause_minutes).minutes
      self.save
      signal = TradingSignal.new
      signal.name = "Stop Loss Open"
      signal.trading_operation_id = operation.id
      signal.open_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = "Stop Loss Open after loss of #{@stop_loss_value} for #{@stop_loss_pause_minutes} minutes"
      signal.save
      log_if("Opened Stop Loss Open signal #{signal.inspect}")
    end
  end

  def no_delete!
    self.no_delete = true
    self.save
  end

  def marshall_simulated_trading_signals
    self.simulated_trading_signals = Marshal.dump(@simulated_trading_signals_array) if @simulated_trading_signals_array
  end

  def demarshall_simulated_trading_signals
    begin
      @simulated_trading_signals_array = Marshal.load(self.simulated_trading_signals) if self.simulated_trading_signals
    rescue
      @simulated_trading_signals_array = []
    end
  end

  def set
    self.trading_strategy_set
  end

  def population
    self.trading_strategy_set.population if self.trading_strategy_set
  end

  def quote_target
    trading_strategy_set.trading_strategy_population.quote_target
  end

  def import_binary_parameters(parameters)
    self.binary_parameters = parameters
  end

  def import_float_parameters(parameters)
    self.float_parameters = parameters
  end

  def setup_parameters
    if population and self.binary_parameters and self.binary_parameters.length>0 and self.float_parameters and self.float_parameters.length>2
      @strategy_buy_short = self.binary_parameters[0]
      self.open_how_far_back_milliseconds = [1000*60,(self.float_parameters[0]*(1000*60*population.simulation_max_minutes_back)/60).abs].max
      self.close_how_far_back_milliseconds = [1000*60,(self.float_parameters[1]*(1000*60*population.simulation_max_minutes_back)/60).abs].max
      @open_magnitude_signal_trigger  = self.float_parameters[2]/1000000.0
      @close_magnitude_signal_trigger  = self.float_parameters[3]/1000000.0
      @stop_01_value  = self.float_parameters[4].abs.to_i
      @stop_02_value  = self.float_parameters[5].abs.to_i
      @stop_03_value  = self.float_parameters[6].abs.to_i
      @stop_04_value  = self.float_parameters[7].abs.to_i
      @stop_05_value  = self.float_parameters[8].abs.to_i
      @stop_06_value  = self.float_parameters[9].abs.to_i
      @stop_07_value  = self.float_parameters[10].abs.to_i
      @stop_08_value  = self.float_parameters[11].abs.to_i
      @days_back_long_short = self.float_parameters[12].abs.to_i/10
      @min_difference_for_close = self.float_parameters[13].abs.to_i
      @stop_loss_value  = self.float_parameters[14].abs.to_i
      @stop_loss_pause_minutes  = self.float_parameters[15].abs.to_i
    end
  end

  def long?
    value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(@days_back_long_short).days).ask
    if value_then<=@current_quote_value
      true
    else
      false
    end
  end

  def get_chart_data(current_day=nil)
    quote_values = []
    current_day = current_day ? current_day : Date.today
    from_date = current_day.to_datetime.beginning_of_day
    to_date = current_day.to_datetime.end_of_day
    quote_target.quote_values.select("ask, data_time, MINUTE(data_time) as CTMINUTE, MIN(ask) AS MINASK, MAX(ask) AS MAXASK").
                              where(["data_time>=? AND data_time<=?",from_date.to_formatted_s(:db),to_date.to_formatted_s(:db)]).
                              group("MINUTE(data_time), HOUR(data_time)").each do |quote_value|
      quote_values<<"{date: new Date(#{quote_value.data_time.year},#{quote_value.data_time.month-1},#{quote_value.data_time.day},#{quote_value.data_time.hour},#{quote_value.CTMINUTE},0,0), value: #{quote_value.ask}, volume: #{0}}"
    end
    quote_values.join(",")
  end

  def get_trading_events(current_day=nil)
    @day = current_day ? current_day : Date.today
    @from_hour = trading_strategy_set.trading_time_frame.from_hour
    @to_hour = trading_strategy_set.trading_time_frame.to_hour
    events = []
    events << simulated_trading_signal_to_amchart({:name=>"B", :current_date_time=>DateTime.parse("#{@day} #{@from_hour}:00:00"), :background_color=>"#22ee22",
                                                  :description=>"Trading Time Frame Start"})
    events << simulated_trading_signal_to_amchart({:name=>"E", :current_date_time=>DateTime.parse("#{@day} #{@to_hour}:00:00"), :background_color=>"#ff6655",
                                                  :description=>"Trading Time Frame Stop"})
    @simulated_trading_signals_array.each do |signal|
      events << simulated_trading_signal_to_amchart(signal)
      if signal[:name]=="Short Open" or signal[:name]=="Long Open"
        events << simulated_trading_signal_to_amchart({:name=>"F", :type=>"flag", :current_date_time=>signal[:current_date_time]-(self.open_how_far_back_milliseconds/1000/60).minutes, :background_color=>"#aaccff",
                                                       :description=>"From here"})
      end
      if signal[:name]=="Short Close" or signal[:name]=="Long Close"
        dstart = signal[:description].index("difference")
        cstart = signal[:description].index("current")
        gained = signal[:description][dstart+11..cstart-2] if cstart and dstart
#        events << simulated_trading_signal_to_amchart({:name=>"#{gained}", :type=>"sign", :current_date_time=>signal[:current_date_time], :background_color=>"#ffffff",
#                                                       :description=>"Gained #{gained}"})
      end
    end
    events.join(",")
  end

  def simulated_trading_signal_to_amchart(event)
    background_color = event[:background_color] ? event[:background_color] : "#cccccc"
    event_type = event[:type] ? event[:type] : "sign"
    event_type = "arrowUp" if event[:name]=="Short Open" or event[:name]=="Long Open"
    event_type = "arrowDown" if event[:name]=="Short Close" or event[:name]=="Long Close"
    "{ date: new Date(#{event[:current_date_time].year},#{event[:current_date_time].month-1},#{event[:current_date_time].day},#{event[:current_date_time].hour},#{event[:current_date_time].minute},0,0), type: '#{event_type}', \
             backgroundColor: '#{background_color}', graph: graph1, text: '#{event[:name]}', description: '#{event[:description]}'}"
  end

  def evaluate(quote_target, date_time=DateTime.now, last_time_segment=false, trading_operation_id=nil, trading_position_id=nil)
    @quote_target = quote_target
    @trading_operation_id = trading_operation_id
    @trading_position_id = trading_position_id
    @current_date_time = date_time
    @trading_position = TradingPosition.find(@trading_position_id) if @trading_position_id
    if @evolution_mode
      @current_quote = @quote_target.get_quote_value_by_time_stamp(@current_date_time)
    else
      @current_quote = @quote_target.get_quote_value_by_time_stamp
    end
    if @current_quote
      @current_quote_value = @current_quote.ask
      log_if("Evaluate #{long? ? "Long" : "Short"}")
      if (@trading_position and @trading_position.trading_signal.name=="Long Open") or (@current_position_units and @long_open)
        if match_close_conditions or last_time_segment
          trigger_long_close_signal
          @long_open = nil
        end
      elsif (@trading_position and @trading_position.trading_signal.name=="Short Open") or (@current_position_units and @short_open)
        if match_close_conditions or last_time_segment
          trigger_short_close_signal
          @short_open = nil
        end
      elsif long?
        trigger_long_open_signal if match_open_conditions
      elsif not long?
        trigger_short_open_signal if match_open_conditions
      end
    else
      Rails.logger.warn("No quote value for #{@current_date_time}!")
    end
    log_if "Current date time #{@current_date_time} quote_value: #{@current_quote_value} units: #{@current_position_units} current: #{@current_capital_position} last_opened: #{@last_opened_position_value}"
  end

  # MATCH OPEN CLOSE

  def match_open_conditions
    @quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.open_how_far_back_milliseconds/1000.0).seconds).ask
    log_if("Testing open: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.open_how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    if quote_value_change==0.0
      return false
    elsif quote_value_change>0.0 and not long?
      log_if(@open_reason = "Testing short open: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger.abs)}")
      magnitude = quote_value_change.abs/@current_quote_value
    elsif quote_value_change<0.0 and long?
      log_if(@open_reason = "Testing long open: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger.abs)}")
      magnitude = quote_value_change.abs/@current_quote_value
    else
      log_if("Testing open: Has gone the wrong direction")
      return false
    end
    magnitude>@open_magnitude_signal_trigger.abs
  end

  def match_close_conditions
    log_if("--- Match Close Conditions")
    if quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.close_how_far_back_milliseconds/1000.0).seconds)
      @quote_value_then = quote_value_then.ask
    else
      Rails.logger.error("Can't find ask for #{@current_date_time-(self.close_how_far_back_milliseconds/1000.0).seconds}")
      return false
    end
    log_if("Testing close: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.close_how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then

    # CHECK STOPS
    if @trading_position
      log_if("Checking trading position #{@trading_position.id} #{@trading_position.created_at+2.hours} #{DateTime.now} #{@current_quote_value}<#{@trading_position.value_open}")
      currently_at = @current_quote_value * @trading_position.units
      opened_at = @trading_position.value_open * @trading_position.units
      open_timeout = match_stops(@trading_position.value_open,@trading_position.created_at,DateTime.now,opened_at,currently_at)
    elsif @last_opened_position_value
      currently_at = @current_quote_value * DEFAULT_POSITION_UNITS
      opened_at = @last_opened_position_value * DEFAULT_POSITION_UNITS
      open_timeout = match_stops(@last_opened_position_value,@last_opened_position_datetime,@current_date_time,opened_at,currently_at)
    end
    open_difference = (opened_at-currently_at).abs
    if open_timeout
      return true
    elsif quote_value_change==0.0
      return false
    elsif quote_value_change>0.0 and not long?
      log_if("close_conditions: Has gone up")
      return false
    elsif quote_value_change<0.0 and long?
      log_if("close_conditions: Has gone down")
      return false
    else
      if @trading_position and ((not long? and @current_quote_value<@trading_position.value_open) or (long? and @current_quote_value>@trading_position.value_open))
        if open_difference>@min_difference_for_close
          log_if(@close_reason = "Testing close: change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@close_magnitude_signal_trigger.abs)}")
          magnitude = quote_value_change.abs/@current_quote_value
        else
          return false
        end
      elsif @trading_position
        return false
      elsif @last_opened_position_value and ((not long? and @current_quote_value<@last_opened_position_value) or (long? and @current_quote_value>@last_opened_position_value))
        if open_difference>@min_difference_for_close
          log_if(@close_reason = "Testing close: change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@close_magnitude_signal_trigger.abs)}")
          magnitude = quote_value_change.abs/@current_quote_value
        else
          return false
        end
      else
        return false
      end
    end
    magnitude>@close_magnitude_signal_trigger.abs
  end

  # STOPS

  def match_stops(value_open,time_open,current_time,opened_at,currently_at)
    open_timeout = false
    log_if("Checking timeout #{(time_open+2.hour)}<#{current_time}")
    if long?
      @profit = @current_quote_value>value_open
      open_difference = currently_at-opened_at
    else
      @profit = @current_quote_value<value_open
      open_difference = opened_at-currently_at
    end
    if (time_open+30.minutes)<current_time
      log_if("30 minutes timeout")
        if @profit and open_difference>@stop_01_value and open_difference<@stop_02_value
        log_if("Closing out in profits")
         open_timeout = true
         @close_reason = "Forced in profit more than #{@stop_01_value}-#{@stop_02_value} after 30 minutes but value is less at #{@current_quote_value} value open was #{value_open}"
       end
     end
     if (time_open+2.hours)<current_time
       log_if("2 hour timeout")
       if @profit and open_difference>@stop_03_value
         log_if("Closing out in profits")
         open_timeout = true
         @close_reason = "Forced in profit more than #{@stop_03_value} #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
       if open_difference<-(@stop_04_value)
         log_if("Closing out with loss min -#{@stop_04_value}")
         open_timeout = true
         @close_reason = "Forced at loss with more than #{@stop_04_value} #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
     end
     if (time_open+4.hours)<current_time
       log_if("4 hour timeout")
       if @profit and open_difference>@stop_05_value
         log_if("Closing out in profits")
         open_timeout = true
         @close_reason = "Forced in profit more than #{@stop_05_value} #{open_difference} after 4 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
       if open_difference<-((@stop_06_value))
         log_if("Closing out with loss min -250")
         open_timeout = true
         @close_reason = "Forced at loss with more than #{@stop_06_value} #{open_difference} after 4 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
     end
     if (time_open+6.hours)<current_time
       log_if("6 hour timeout")
       if @profit and open_difference>@stop_07_value
         log_if("Closing out in profits")
         open_timeout = true
         @close_reason = "Forced in profit more than #{@stop_07_value} #{open_difference} after 6 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
       if open_difference<-(@stop_08_value)
         log_if("Closing out with loss -150")
         open_timeout = true
         @close_reason = "Forced at loss with more than #{@stop_08_value} #{open_difference} after 6 hours but value is less at #{@current_quote_value} value open was #{value_open}"
       end
     end
     if (time_open+12.hours)<current_time
       log_if("12 hour timeout")
       log_if("Closing out with loss forced")
       open_timeout = true
       @close_reason = "Forced with #{open_difference} after 12 hours but value is less at #{@current_quote_value} value open was #{value_open}"
    end
    open_timeout
  end

  # TRIGGERS

  def trigger_short_open_signal
    capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
    log_if("--> Trigger short OPEN")
    if @evolution_mode
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @short_open = true
        @last_opened_position_value = @current_quote_value
        @last_opened_position_datetime = @current_date_time
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        @daily_signals+=1
        @simulated_trading_signals_array<<{:name=>"Short Open", :current_date_time=>@current_date_time, :description=>"I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}"}
        log_if("    I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}")
      else
        Rails.warn("Out of cash: #{self.inspect}")
      end
    else
      if @trading_operation_id and operation = TradingOperation.where(["id=?",@trading_operation_id]).first
        signal = operation.trading_signals.where("name='Short Open'").order("created_at DESC").first
        if signal and (signal.created_at+MINUTES_BETWEEN_POS_OPENINGS>DateTime.now)
          log_if("Not putting it on because of short time since #{signal.inspect} - #{signal.created_at+MINUTES_BETWEEN_POS_OPENINGS}>#{DateTime.now}")
          return
        end
      end
      return if operation.trading_positions.where("open=1").count>2
      self.no_delete!
      signal = TradingSignal.new
      signal.name = "Short Open"
      signal.trading_operation_id = @trading_operation_id
      signal.open_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @open_reason
      signal.save
      log_if("Opened signal #{signal.inspect}")
    end
  end

  def trigger_long_open_signal
    capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
    log_if("--> Trigger long OPEN")
    if @evolution_mode
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @long_open = true
        @last_opened_position_value = @current_quote_value
        @last_opened_position_datetime = @current_date_time
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        @daily_signals+=1
        @simulated_trading_signals_array<<{:name=>"Long Open", :current_date_time=>@current_date_time, :description=>"I bought #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}"}
        log_if("    I bought #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}")
      else
        Rails.warn("Out of cash: #{self.inspect}")
      end
    else
      if @trading_operation_id and operation = TradingOperation.where(["id=?",@trading_operation_id]).first
        signal = operation.trading_signals.where("name='Long Open'").order("created_at DESC").first
        if signal and (signal.created_at+MINUTES_BETWEEN_POS_OPENINGS>DateTime.now)
          log_if("Not putting it on because of short time since #{signal.inspect} - #{signal.created_at+MINUTES_BETWEEN_POS_OPENINGS}>#{DateTime.now}")
          return
        end
      end
      return if operation.trading_positions.where("open=1").count>2
      self.no_delete!
      signal = TradingSignal.new
      signal.name = "Long Open"
      signal.trading_operation_id = @trading_operation_id
      signal.open_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @open_reason
      signal.save
      log_if("Opened signal #{signal.inspect}")
    end
  end

  def trigger_short_close_signal
    log_if("--> Trigger short CLOSE")
    if @evolution_mode
      log_if("--> Trigger short CLOSE investment")
      opened_at = @last_opened_position_value * @current_position_units
      currently_at = @current_quote_value * @current_position_units
      difference = opened_at-currently_at
      @current_capital_position+=opened_at+difference
      log_if("    opened_at #{opened_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}")
      @simulated_trading_signals_array<<{:name=>"Short Close", :current_date_time=>@current_date_time, :description=>"Short Close #{@close_reason} opened_at #{opened_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}"}
      @current_position_units = nil
      self.number_of_evolution_trading_signals+=1
      @daily_signals+=1
      @daily_p_and_l+=difference
    else
      self.no_delete!
      signal = TradingSignal.new
      signal.name = "Short Close"
      signal.trading_operation_id = @trading_operation_id
      signal.trading_position_id = @trading_position_id
      signal.close_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @close_reason
      signal.save
    end
  end

  def trigger_long_close_signal
    log_if("--> Trigger long CLOSE")
    if @evolution_mode
      log_if("--> Trigger long CLOSE investment")
      bought_at = @last_opened_position_value * @current_position_units
      currently_at = @current_quote_value * @current_position_units
      difference = currently_at-bought_at
      @current_capital_position+=bought_at+difference
      log_if("    Bought_at #{bought_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}")
      @simulated_trading_signals_array<<{:name=>"Long Close", :current_date_time=>@current_date_time, :description=>"Long Close #{@close_reason} opened_at #{bought_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}"}
      @current_position_units = nil
      self.number_of_evolution_trading_signals+=1
      @daily_signals+=1
      @daily_p_and_l+=difference
    else
      self.no_delete!
      signal = TradingSignal.new
      signal.name = "Long Close"
      signal.trading_operation_id = @trading_operation_id
      signal.trading_position_id = @trading_position_id
      signal.close_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @close_reason
      signal.save
    end
  end


  def with_precision(number)
    number_with_precision number, :precision => 6
  end

  def out_of_range_attributes?
    if self.open_how_far_back_milliseconds < 60000.0
      self.simulated_fitness_failure_reason = "O.MS <"
      true
    elsif self.open_how_far_back_milliseconds > (1000*60*population.simulation_max_minutes_back).to_f
      self.simulated_fitness_failure_reason = "O.MS >"
      true
    elsif self.close_how_far_back_milliseconds < 60000.0
      self.simulated_fitness_failure_reason = "C.MS <"
      true
    elsif self.close_how_far_back_milliseconds > (1000*60*population.simulation_max_minutes_back).to_f
      self.simulated_fitness_failure_reason = "C.MS >"
      true
    elsif @open_magnitude_signal_trigger < -1000.0
      self.simulated_fitness_failure_reason = "Open M <"
    true
    elsif @open_magnitude_signal_trigger > 1000.0
      self.simulated_fitness_failure_reason = "Open M >"
      true
    elsif @close_magnitude_signal_trigger < -1000.0
      self.simulated_fitness_failure_reason = "Close M <"
      true
    elsif @close_magnitude_signal_trigger > 1000.0
      self.simulated_fitness_failure_reason = "Close M >"
      true
    else
      false
    end
  end

  def fitness
    @quote_target = population.quote_target
    log_if("#{population.simulation_end_date.to_date}") if population.simulation_end_date
    if population.simulation_end_date
      self.simulated_end_date = population.simulation_end_date ? population.simulation_end_date.to_date : Date.today
      self.simulated_start_date = (self.simulated_end_date.to_date-population.simulation_days_back).to_date
    else
      self.simulated_start_date = Date.today-population.simulation_days_back
      self.simulated_end_date = Date.today-1
    end
    setup_parameters
    if out_of_range_attributes?
      self.simulated_fitness = FAILED_FITNESS_VALUE
    else
      time_start_fitness = Time.now.to_i
      @evolution_mode = true
      @current_position_units = nil
      @last_opened_position_value = nil
      @simulated_trading_signals_array = []
      @current_capital_position = @start_capital_position = DEFAULT_START_CAPITAL
      @from_hour = trading_strategy_set.trading_time_frame.from_hour
      @to_hour = trading_strategy_set.trading_time_frame.to_hour
      @daily_signals = number_of_evolution_trading_signals = 0
      @daily_p_and_l = 0.0
      @stop_loss_paused_until = nil
      @current_simulation_time = nil
      (self.simulated_start_date.to_date..self.simulated_end_date.to_date).each do |day|
        (@from_hour..@to_hour).each do |hour|
          (0..59).step(5).each do |minute|
            @current_simulation_time = DateTime.parse("#{day} #{hour}:#{minute}:00")
            if population.stop_loss_enabled and @stop_loss_paused_until and @stop_loss_paused_until < @current_simulation_time and not @current_position_units
              next
            elsif population.stop_loss_enabled and @stop_loss_paused_until and not @current_position_units
              @simulated_trading_signals_array<<{:name=>"Stop Loss Close", :current_date_time=>@current_date_time, :description=>"Stop Loss Closed after #{@stop_loss_pause_minutes} minutes"}
              @stop_loss_paused_until = nil
              @daily_p_and_l = 0.0
            end

            evaluate(@quote_target,@current_simulation_time,false)

            if population.stop_loss_enabled and @daily_p_and_l<-(@stop_loss_value) and not @current_position_units
              @stop_loss_paused_until = @current_simulation_time+(@stop_loss_pause_minutes).minutes
              @simulated_trading_signals_array<<{:name=>"Stop Loss Open", :current_date_time=>@current_date_time, :description=>"Stop Loss Open after loss of #{@stop_loss_value} for #{@stop_loss_pause_minutes} minutes"}
            end
            break if @daily_signals>population.simulation_max_daily_trading_signals
          end
          break if @daily_signals>population.simulation_max_daily_trading_signals
        end
        break if @daily_signals>population.simulation_max_daily_trading_signals
        @daily_signals = 0
        @daily_p_and_l = 0.0
      end
      evaluate(@quote_target,@current_simulation_time,true) if @current_position_units
      log_if("Number of trading signals: #{self.number_of_evolution_trading_signals}")
      if self.number_of_evolution_trading_signals<population.simulation_min_overall_trading_signals
        self.simulated_fitness_failure_reason = "Min Signals O"
        self.simulated_fitness = FAILED_FITNESS_VALUE
      elsif self.number_of_evolution_trading_signals>population.simulation_max_overall_trading_signals
          self.simulated_fitness_failure_reason = "Max Signals O"
          self.simulated_fitness = FAILED_FITNESS_VALUE
      elsif @daily_signals>population.simulation_max_daily_trading_signals
        self.simulated_fitness_failure_reason = "Max Signals D"
        self.simulated_fitness = FAILED_FITNESS_VALUE
      elsif not (@current_capital_position and @start_capital_position)
        self.simulated_fitness_failure_reason = "No Positions"
        self.simulated_fitness = FAILED_FITNESS_VALUE
      else
        self.simulated_fitness  = @current_capital_position-@start_capital_position
      end
      log_if("Fitness took #{Time.now.to_i-time_start_fitness} for #{self.id}")
    end
    self.save
    self.simulated_fitness
  end

  private

  def log_if(string)
    if true or @trading_position
      Rails.logger.info(string)
    end
  end

  def current_quote_value
  end

  def quote_value_in_the_past
  end

  def generate_trading_signal(signal)
     TradingSignal.create(:trading_strategy_id=>self.id, :signal=>signal)
  end
end
