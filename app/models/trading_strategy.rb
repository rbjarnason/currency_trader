class TradingStrategy < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  DEFAULT_START_CAPITAL = 100000000.0
  DEFAULT_POSITION_UNITS = 50000.0
  FAILED_FITNESS_VALUE = -999999.0

  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
  has_many   :trading_signals, :dependent => :delete_all

  # Parameters
  # 0: Time to look back in ms (10000)
  # 1: Magnitude of change since time in percent (0.01)
  # 2: Type of trading signal (Buy or Sell)
  serialize :binary_parameters, Array
  serialize :float_parameters, Array
  serialize :simulated_trading_signals, Array

  attr_reader :strategy_buy_short, :open_magnitude_signal_trigger, :close_magnitude_signal_trigger

  after_initialize :setup_parameters
  after_save :setup_parameters

  def set
    self.trading_strategy_set
  end

  def population
    self.trading_strategy_set.population
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
    if self.binary_parameters and self.binary_parameters.length>0 and self.float_parameters and self.float_parameters.length>2
      @strategy_buy_short = self.binary_parameters[0]
      self.how_far_back_milliseconds = [1000*60,(self.float_parameters[0]*(1000*60*population.simulation_max_minutes_back)/60).abs].max
      @open_magnitude_signal_trigger  = self.float_parameters[1]/100000.0
      @close_magnitude_signal_trigger  = self.float_parameters[2]/100000.0
    end
  end

  def get_chart_data(current_day=nil)
    quote_values = []
    current_day = current_day ? current_day : Date.today
    from_date = current_day.to_datetime.beginning_of_day
    to_date = current_day.to_datetime.end_of_day
    quote_target.quote_values.select("ask, created_at, MINUTE(created_at) as CTMINUTE, MIN(ask) AS MINASK, MAX(ask) AS MAXASK").
                              where(["created_at>=? AND created_at<=?",from_date.to_formatted_s(:db),to_date.to_formatted_s(:db)]).
                              group("MINUTE(created_at), HOUR(created_at)").each do |quote_value|
      quote_values<<"{date: new Date(#{quote_value.created_at.year},#{quote_value.created_at.month-1},#{quote_value.created_at.day},#{quote_value.created_at.hour},#{quote_value.CTMINUTE},0,0), value: #{quote_value.ask}, volume: #{0}}"
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
    simulated_trading_signals.each do |signal|
      events << simulated_trading_signal_to_amchart(signal)
      if signal[:name]=="Short Open"
        events << simulated_trading_signal_to_amchart({:name=>"F", :type=>"flag", :current_date_time=>signal[:current_date_time]-(self.how_far_back_milliseconds/1000/60).minutes, :background_color=>"#aaccff",
                                                       :description=>"From here"})
      end
      if signal[:name]=="Short Close"
        dstart = signal[:description].index("difference")
        cstart = signal[:description].index("current")
        gained = signal[:description][dstart+11..cstart-2]
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
    @quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.how_far_back_milliseconds/1000.0).seconds).ask
    Rails.logger.debug("Testing short open: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    if quote_value_change==0.0
      return false
    elsif quote_value_change>=0.0
      Rails.logger.debug(@short_open_reason = "Testing short open: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger)}")
      magnitude = quote_value_change.abs/@current_quote_value
    else
      Rails.logger.debug("Testing short open: Has gone down")
      return false
    end
    magnitude>@open_magnitude_signal_trigger.abs
  end

  def trigger_short_open_signal
    capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
    Rails.logger.info("--> Trigger short OPEN")
    if @evolution_mode
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @last_opened_position_value = @current_quote_value
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        @daily_signals+=1
        simulated_trading_signals<<{:name=>"Short Open", :current_date_time=>@current_date_time, :description=>"I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}"}
        Rails.logger.debug("    I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}")
      else
        Rails.warn("Out of cash: #{self.inspect}")
      end
    else
      signal = TradingSignal.new
      signal.name = "Short Open"
      signal.trading_operation_id = @trading_operation_id
      signal.open_quote_value = @current_quote_value
      signal.trading_strategy_id = self.id
      signal.reason = @short_open_reason
      signal.save
    end
  end

  def match_short_close_conditions
    Rails.logger.info("--- MATCH SHORT")
    if quote_value_then = @quote_target.get_quote_value_by_time_stamp(@current_date_time-(self.how_far_back_milliseconds/1000.0).seconds)
      @quote_value_then = quote_value_then.ask
    else
      Rails.logger.error("Can't find ask for #{@current_date_time-(self.how_far_back_milliseconds/1000.0).seconds}")
      return false
    end
    Rails.logger.info("Testing short close: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{self.how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    short_timeout = false
    if @trading_position
      Rails.logger.info("!!!!! Checking trading position #{@trading_position.id} #{@trading_position.created_at+2.hours} #{DateTime.now} #{@current_quote_value}<#{@trading_position.value_open}")
      if @trading_position
        Rails.logger.info("Checking timeout #{(@trading_position.created_at+2.hour)}<#{DateTime.now}")
        shorted_at = @trading_position.value_open *  @trading_position.units
        currently_at = @current_quote_value * @trading_position.units
        open_difference = shorted_at-currently_at
        if (@trading_position.created_at+2.hours)<DateTime.now
          Rails.logger.info("2 hour timeout")
          if (@current_quote_value<@trading_position.value_open) and open_difference>80
            Rails.logger.info("Closing out in profits")
            short_timeout = true
            @short_close_reason = "Forced in profit >80 after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
          if open_difference<-150
            Rails.logger.info("Closing out with loss min -150")
            short_timeout = true
            @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
        end
        if (@trading_position.created_at+4.hours)<DateTime.now
          Rails.logger.info("4 hour timeout")
          if (@current_quote_value<@trading_position.value_open) and open_difference>40
            Rails.logger.info("Closing out in profits")
            short_timeout = true
            @short_close_reason = "Forced in profit >40 after4 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
          if open_difference<-100
            Rails.logger.info("Closing out with loss min -100")
            short_timeout = true
            @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
        end
        if (@trading_position.created_at+6.hours)<DateTime.now
          Rails.logger.info("6 hour timeout")
          if (@current_quote_value<@trading_position.value_open)
            Rails.logger.info("Closing out in profits")
            short_timeout = true
            @short_close_reason = "Forced in profit >0 after 6 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
          if open_difference<-50
            Rails.logger.info("Closing out with loss -50")
            short_timeout = true
            @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
          end
        end
        if (@trading_position.created_at+8.hours)<DateTime.now
          Rails.logger.info("8 hour timeout")
          Rails.logger.info("Closing out with loss forced")
          short_timeout = true
          @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
        end
        if open_difference<-500
          Rails.logger.info("No timeout. Closing out with loss -500")
          short_timeout = true
          @short_close_reason = "Forced at loss with #{open_difference} after 2 hours but value is less at #{@current_quote_value} value open was #{@trading_position.value_open}"
        end
      end
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
        Rails.logger.debug(@short_close_reason = "Testing short close: value change #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@close_magnitude_signal_trigger.abs)}")
        magnitude = quote_value_change.abs/@current_quote_value
      else
        return false
      end
    end
    magnitude>@close_magnitude_signal_trigger.abs
  end

  # If falling quickly hold on if falling and if making profits...

  def trigger_short_close_signal
    Rails.logger.info("--> Trigger short CLOSE")
    if @evolution_mode
      Rails.logger.debug("--> Trigger short CLOSE investment")
      shorted_at = @last_opened_position_value * @current_position_units
      currently_at = @current_quote_value * @current_position_units
      difference = shorted_at-currently_at
      @current_capital_position+=shorted_at+difference
      Rails.logger.debug("    Shorted_at #{shorted_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}")
      simulated_trading_signals<<{:name=>"Short Close", :current_date_time=>@current_date_time, :description=>"Shorted_at #{shorted_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}"}
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
    magnitude_of_change_since(self.how_far_back_milliseconds)>@open_magnitude_signal_trigger
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
    if self.how_far_back_milliseconds < 60000.0
      self.simulated_fitness_failure_reason = "MS <"
      true
    elsif self.how_far_back_milliseconds > (1000*60*population.simulation_max_minutes_back).to_f
      self.simulated_fitness_failure_reason = "MS >"
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
    Rails.logger.debug("XXXXXXXXXXXXXXX #{population.simulation_end_date.to_date}") if population.simulation_end_date
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
          self.simulated_fitness_failure_reason = "Min Signals O"
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
