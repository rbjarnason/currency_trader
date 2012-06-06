#TODO Make stop signals evolve

class TradingStrategy < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  DEFAULT_START_CAPITAL = 100000000.0
  DEFAULT_POSITION_UNITS = 50000.0
  FAILED_FITNESS_VALUE = -999999.0

  MINUTES_BETWEEN_POS_OPENINGS = 2.minutes

  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
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

  attr_reader :strategy_buy_short, :open_magnitude_signal_trigger, :close_magnitude_signal_trigger, :simulated_trading_signals_array

  after_initialize :setup_parameters
  after_save :setup_parameters

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
      @open_magnitude_signal_trigger  = self.float_parameters[2]/100000.0
      @close_magnitude_signal_trigger  = self.float_parameters[3]/100000.0
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
      if signal[:name]=="Short Open"
        events << simulated_trading_signal_to_amchart({:name=>"F", :type=>"flag", :current_date_time=>signal[:current_date_time]-(self.open_how_far_back_milliseconds/1000/60).minutes, :background_color=>"#aaccff",
                                                       :description=>"From here"})
      end
      if signal[:name]=="Short Close"
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
    event_type = "arrowUp" if event[:name]=="Short Open"
    event_type = "arrowDown" if event[:name]=="Short Close"
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
    if  @current_quote
      @current_quote_value = @current_quote.ask
      if true or @strategy_buy_short==1
        Rails.logger.debug("Short mode")
        if @current_position_units or @trading_position_id
          Rails.logger.debug("Holding position")
          trigger_short_close_signal if match_short_close_conditions or last_time_segment
        else
          Rails.logger.debug("Not holding position")
          trigger_short_open_signal if match_short_open_conditions
        end
      else
        Rails.logger.debug("Long mode")
        if not @current_position_units
          Rails.logger.debug("Not holding position")
          trigger_long_open_signal if match_long_open_conditions
        else
          Rails.logger.debug("Holding position")
          trigger_long_close_signal if match_long_close_conditions or last_time_segment
        end
      end
    else
      Rails.logger.warn("No quote value for #{@current_date_time}!")
    end
    Rails.logger.debug "Current date time #{@current_date_time} quote_value: #{@current_quote_value} units: #{@current_position_units} current: #{@current_capital_position} last_opened: #{@last_opened_position_value}"
    Rails.logger.debug("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    Rails.logger.debug("")
  end

  def match_short_open_conditions
    #return true
    @quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.open_how_far_back_milliseconds/1000.0).seconds).ask
    Rails.logger.debug("Testing short open: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.open_how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    if quote_value_change==0.0
      return false
    elsif quote_value_change>=0.0
      Rails.logger.debug(@short_open_reason = "Testing short open: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger.abs)}")
      magnitude = quote_value_change.abs/@current_quote_value
    else
      Rails.logger.debug("Testing short open: Has gone down")
      return false
    end
    magnitude>@open_magnitude_signal_trigger.abs
  end

  def trigger_short_open_signal
    capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
    Rails.logger.debug("--> Trigger short OPEN")
    if @evolution_mode
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @last_opened_position_value = @current_quote_value
        @last_opened_position_datetime = @current_date_time
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        @daily_signals+=1
        @simulated_trading_signals_array<<{:name=>"Short Open", :current_date_time=>@current_date_time, :description=>"I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}"}
        Rails.logger.debug("    I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}")
      else
        Rails.warn("Out of cash: #{self.inspect}")
      end
    else
      if @trading_operation_id and operation = TradingOperation.where(["id=?",@trading_operation_id]).first
        signal = operation.trading_signals.where("name='Short Open'").order("created_at DESC").first
        if signal and (signal.created_at+MINUTES_BETWEEN_POS_OPENINGS>DateTime.now)
          Rails.logger.info("Not putting it on because of short time since #{signal.inspect} - #{signal.created_at+MINUTES_BETWEEN_POS_OPENINGS}>#{DateTime.now}")
          return
        end
      end
      return if operation.trading_positions.where("open=1").count>2
      signal = TradingSignal.new
      signal.name = "Short Open"
      signal.trading_operation_id = @trading_operation_id
      signal.open_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @short_open_reason
      signal.save
      Rails.logger.info("Opened signal #{signal.inspect}")
    end
  end

  def match_stops(value_open,time_open,current_time,shorted_at,currently_at)
    short_timeout = false
    Rails.logger.debug("Checking timeout #{(time_open+2.hour)}<#{current_time}")
    open_difference = shorted_at-currently_at
#   if (time_open+30.minutes)<current_time
#      Rails.logger.debug("30 minutes timeout")
#      if (@current_quote_value<value_open) and open_difference>190 and open_difference<150
#        Rails.logger.debug("Closing out in profits")
#        short_timeout = true
#        @short_close_reason = "Forced in profit more than 100-150 after 30 minutes but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#    end
#    if (time_open+2.hours)<current_time
#      Rails.logger.debug("2 hour timeout")
#      if (@current_quote_value<value_open) and open_difference>100
#        Rails.logger.debug("Closing out in profits")
#        short_timeout = true
#        @short_close_reason = "Forced in profit more than 100 after 2 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#      if open_difference<-350
#        Rails.logger.debug("Closing out with loss min -350")
#        short_timeout = true
#        @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#    end
 #   if (time_open+4.hours)<current_time
#      Rails.logger.debug("4 hour timeout")
#      if (@current_quote_value<value_open) and open_difference>60
#        Rails.logger.debug("Closing out in profits")
#        short_timeout = true
#        @short_close_reason = "Forced in profit more than 60 after 4 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#      if open_difference<-250
#        Rails.logger.debug("Closing out with loss min -250")
#        short_timeout = true
#        @short_close_reason = "Forced at loss with #{open_difference} after 4 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#    end
#    if (time_open+6.hours)<current_time
#      Rails.logger.debug("6 hour timeout")
#      if (@current_quote_value<value_open)
#        Rails.logger.debug("Closing out in profits")
#        short_timeout = true
#        @short_close_reason = "Forced in profit more than 0 after 6 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#      if open_difference<-150
#        Rails.logger.debug("Closing out with loss -150")
#        short_timeout = true
#        @short_close_reason = "Forced at loss with #{open_difference} after 6 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#      end
#    end
#    if (time_open+8.hours)<current_time
#      Rails.logger.debug("8 hour timeout")
#      Rails.logger.debug("Closing out with loss forced")
#      short_timeout = true
#      @short_close_reason = "Forced with #{open_difference} after 8 hours but value is less at #{@current_quote_value} value open was #{value_open}"
#    end
    if open_difference<-100
      Rails.logger.debug("No timeout. Closing out with loss -100")
      short_timeout = true
      @short_close_reason = "Forced at loss with #{open_difference} -100 value is less at #{@current_quote_value} value open was #{value_open}"
    end
    short_timeout
  end

  def match_short_close_conditions
    Rails.logger.debug("--- MATCH SHORT")
    if quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.close_how_far_back_milliseconds/1000.0).seconds)
      @quote_value_then = quote_value_then.ask
    else
      Rails.logger.error("Can't find ask for #{@current_date_time-(self.close_how_far_back_milliseconds/1000.0).seconds}")
      return false
    end
    Rails.logger.debug("Testing short close: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.close_how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    short_timeout = false
    open_difference = 0.0
    magnitude = 0.0
    if @trading_position
      Rails.logger.debug("!!!!! Checking trading position #{@trading_position.id} #{@trading_position.created_at+2.hours} #{DateTime.now} #{@current_quote_value}<#{@trading_position.value_open}")
      shorted_at = @trading_position.value_open *  @trading_position.units
      currently_at = @current_quote_value * @trading_position.units
      short_timeout = match_stops(@trading_position.value_open,@trading_position.created_at,DateTime.now,shorted_at,currently_at)
      open_difference = shorted_at-currently_at
    elsif @last_opened_position_value
      shorted_at = @last_opened_position_value *  DEFAULT_POSITION_UNITS
      currently_at = @current_quote_value * DEFAULT_POSITION_UNITS
      short_timeout = match_stops(@last_opened_position_value,@last_opened_position_datetime,@current_date_time,shorted_at,currently_at)
      open_difference = shorted_at-currently_at
    end
    if short_timeout
      return true
    elsif quote_value_change==0.0
      return false
    elsif short_timeout
      return true
    elsif quote_value_change>=0.0
      Rails.logger.debug("close_conditions: Has gone up")
      return false
    else
      if @trading_position and (@current_quote_value<@trading_position.value_open)
        if open_difference>75.0
          Rails.logger.debug(@short_close_reason = "Testing short close: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@close_magnitude_signal_trigger.abs)}")
          magnitude = quote_value_change.abs/@current_quote_value
        else
          return false
        end
      elsif @trading_position
        return false
      elsif @last_opened_position_value and @current_quote_value<@last_opened_position_value
        if open_difference>75.0
          Rails.logger.debug(@short_close_reason = "Testing short close: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@close_magnitude_signal_trigger.abs)}")
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

  # If falling quickly hold on if falling and if making profits...

  def trigger_short_close_signal
    Rails.logger.debug("--> Trigger short CLOSE")
    if @evolution_mode
      Rails.logger.debug("--> Trigger short CLOSE investment")
      shorted_at = @last_opened_position_value * @current_position_units
      currently_at = @current_quote_value * @current_position_units
      difference = shorted_at-currently_at
      @current_capital_position+=shorted_at+difference
      Rails.logger.debug("    Shorted_at #{shorted_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}")
      @simulated_trading_signals_array<<{:name=>"Short Close", :current_date_time=>@current_date_time, :description=>"#{@short_close_reason} Shorted_at #{shorted_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}"}
      @current_position_units = nil
      self.number_of_evolution_trading_signals+=1
      @daily_signals+=1
    else
      signal = TradingSignal.new
      signal.name = "Short Close"
      signal.trading_operation_id = @trading_operation_id
      signal.trading_position_id = @trading_position_id
      signal.close_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @short_close_reason
      signal.save
    end
  end

  def match_long_open_conditions
    magnitude_of_change_since(self.open_how_far_back_milliseconds)>@open_magnitude_signal_trigger
  end

  def trigger_long_open_signal
    if @evolution_mode
      capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @last_opened_position_value = @current_quote_value
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        @daily_signals+=1
      else
        Rails.logger.warn("Out of cash: #{self.inspect}")
      end
    else
      # Generate Trading Signal Since
    end
  end

  def match_long_close_conditions
    match_short_close_conditions
  end

  def trigger_long_close_signal
    if @evolution_mode
      @current_capital_position+=@current_position_units*@current_quote_value
      Rails.logger.debug("long_close: #{@current_capital_position}+=#{@current_position_units}*#{@current_quote_value}")
      @current_position_units = nil
      self.number_of_evolution_trading_signals+=1
      @daily_signals+=1
    else
      # Generate Trading Signal Since
    end
  end

  def magnitude_of_change_since(millseconds_since)
    @quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(millseconds_since/1000.0).seconds).ask
    Rails.logger.info("Magnitude of change: then: #{@quote_value_then} current: #{@current_quote_value}")
    quote_value_change = @current_quote_value-@quote_value_then
    if quote_value_change>=0.0
      Rails.logger.debug("Magnitude of change: change: #{quote_value_change.abs} mag: #{quote_value_change.abs/@current_quote_value}")
      quote_value_change/@current_quote_value
    else
      Rails.logger.debug("Magnitude of change: change: #{quote_value_change.abs} mag: #{quote_value_change.abs/@current_quote_value}")
      -(quote_value_change.abs/@current_quote_value)
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
    Rails.logger.debug("#{population.simulation_end_date.to_date}") if population.simulation_end_date
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
      @evolution_mode = true
      @current_position_units = nil
      @last_opened_position_value = nil
      @simulated_trading_signals_array = []
      @current_capital_position = @start_capital_position = DEFAULT_START_CAPITAL
      @from_hour = trading_strategy_set.trading_time_frame.from_hour
      @to_hour = trading_strategy_set.trading_time_frame.to_hour
      @daily_signals = number_of_evolution_trading_signals = 0
      last_minute = false
      (self.simulated_start_date.to_date..self.simulated_end_date.to_date).each do |day|
        (@from_hour..@to_hour).each do |hour|
          (0..59).each do |minute|
            last_minute = (hour==@to_hour and minute==59 and TradingStrategySet::FORCE_RELEASE_POSITION)
            evaluate(@quote_target,DateTime.parse("#{day} #{hour}:#{minute}:00"), last_minute)
            break if last_minute or @daily_signals>population.simulation_max_daily_trading_signals
          end
          break if @daily_signals>population.simulation_max_daily_trading_signals
        end
        break if @daily_signals>population.simulation_max_daily_trading_signals
        @daily_signals=0
      end
      Rails.logger.debug("Number of trading signals: #{self.number_of_evolution_trading_signals}")
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
    end
    self.save
    self.simulated_fitness
  end

  private

  def current_quote_value
  end

  def quote_value_in_the_past
  end

  def generate_trading_signal(signal)
     TradingSignal.create(:trading_strategy_id=>self.id, :signal=>signal)
  end
end
