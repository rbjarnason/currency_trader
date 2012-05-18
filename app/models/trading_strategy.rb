class TradingStrategy < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  DEFAULT_START_CAPITAL = 100000000.0
  DEFAULT_POSITION_UNITS = 50000.0
  FAILED_FITNESS_VALUE = -999999.0
  MAXIMUM_MINUTES_BACK = 60

  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
  has_many   :trading_signals, :dependent => :delete_all

  # Parameters
  # 0: Time to look back in ms (10000)
  # 1: Magnitude of change since time in percent (0.01)
  # 2: Type of trading signal (Buy or Sell)
  serialize :binary_parameters, Array
  serialize :float_parameters, Array

  attr_reader :strategy_buy_short, :how_far_back_milliseconds, :open_magnitude_signal_trigger, :close_magnitude_signal_trigger

  after_initialize :setup_parameters
  after_save :setup_parameters

  def import_binary_parameters(parameters)
    self.binary_parameters = parameters
  end

  def import_float_parameters(parameters)
    self.float_parameters = parameters
  end

  def setup_parameters
    if self.binary_parameters and self.binary_parameters.length>0 and self.float_parameters and self.float_parameters.length>2
      @strategy_buy_short = self.binary_parameters[0]
      @how_far_back_milliseconds = (self.float_parameters[0]*(1000*60*MAXIMUM_MINUTES_BACK)).abs
      @open_magnitude_signal_trigger  = self.float_parameters[1]/100000.0
      @close_magnitude_signal_trigger  = self.float_parameters[2]/100000.0
    end
  end

  def evaluate(quote_target, date_time=DateTime.now, last_time_segment=false)
    @current_date_time = date_time
    if current_quote_value = @quote_target.quote_values.get_one_by_time(@current_date_time)
      @current_quote_value = current_quote_value.ask
      if true or @strategy_buy_short==1
        Rails.logger.debug("Short mode")
        if not @current_position_units
          Rails.logger.debug("Not holding position")
          trigger_short_open_signal if match_short_open_conditions
        else
          Rails.logger.debug("Holding position")
          trigger_short_close_signal if match_short_close_conditions or last_time_segment
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
      Rails.logger.warn("No quote value!")
    end
    Rails.logger.debug "Current date time #{@current_date_time} quote_value: #{@current_quote_value} units: #{@current_position_units} current: #{@current_capital_position} last_opened: #{@last_opened_position_value}"
    Rails.logger.debug("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    Rails.logger.debug("")
  end

  def match_short_open_conditions
    @quote_value_then = @quote_target.quote_values.get_one_by_time(@current_date_time-(@how_far_back_milliseconds/1000.0).seconds).ask
    Rails.logger.debug("Testing short change: #{@quote_value_then} current: #{@current_quote_value} back in minutes: #{@how_far_back_milliseconds/1000/60}")
    quote_value_change = @current_quote_value-@quote_value_then
    if quote_value_change==0.0
      return false
    elsif quote_value_change>=0.0
      Rails.logger.debug("Testing short change: #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger)}")
      magnitude = quote_value_change.abs/@current_quote_value
    else
      Rails.logger.debug("Testing short change: Has gone down")
      return false
      Rails.logger.debug("Testing short change: #{with_precision(quote_value_change.abs)} magnitude: #{with_precision(quote_value_change.abs/@current_quote_value)} > test magnitude: #{with_precision(@open_magnitude_signal_trigger)}")
      magnitude = -(quote_value_change.abs/@current_quote_value)
    end
    magnitude>@open_magnitude_signal_trigger.abs
  end

  def trigger_short_open_signal
    capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
    Rails.logger.debug("--> Trigger short OPEN investment")
    if @evolution_mode
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @last_opened_position_value = @current_quote_value
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
        Rails.logger.debug("    I shorted #{@current_position_units} units for #{capital_investment} leaving #{@current_capital_position}")
      else
        Rails.warn("Out of cash: #{self.inspect}")
      end
    else
      # Generate Trading Signal Since
    end
  end

  def match_short_close_conditions
     difference = @current_quote_value-@last_opened_position_value
     Rails.logger.debug("close_conditions:  current #{@current_quote_value} - last_opened #{@last_opened_position_value} = #{difference}")
     if difference==0.0
       return false
     elsif difference>=0.0
       Rails.logger.debug("close_conditions: Has gone up")
       return false
       Rails.logger.debug("close_conditions: (#{with_precision(@current_quote_value/difference)})>#{with_precision(@close_magnitude_signal_trigger)}=#{(@current_quote_value/difference.abs)>@close_magnitude_signal_trigger}")
       (@current_quote_value/difference.abs)>@close_magnitude_signal_trigger
     else
       Rails.logger.debug("close_conditions: testing #{with_precision(difference.abs/@current_quote_value)}>#{with_precision(@close_magnitude_signal_trigger)}=#{(difference.abs/@current_quote_value).abs>@close_magnitude_signal_trigger}")
       (difference.abs/@current_quote_value).abs>@close_magnitude_signal_trigger.abs
     end
   end

   def trigger_short_close_signal
     if @evolution_mode
       Rails.logger.debug("--> Trigger short CLOSE investment")
       shorted_at = @last_opened_position_value * @current_position_units
       currently_at = @current_quote_value * @current_position_units
       difference = shorted_at-currently_at
       @current_capital_position+=shorted_at+difference
       Rails.logger.debug("    Shorted_at #{shorted_at} currently_at #{currently_at} difference #{difference} current #{@current_capital_position}")
       @current_position_units = nil
     else
       # Generate Trading Signal Since
     end
   end

  def match_long_open_conditions
    magnitude_of_change_since(@how_far_back_milliseconds)>@open_magnitude_signal_trigger
  end

  def trigger_long_open_signal
    if @evolution_mode
      capital_investment = DEFAULT_POSITION_UNITS*@current_quote_value
      if @current_capital_position-capital_investment>0
        @current_position_units = DEFAULT_POSITION_UNITS
        @last_opened_position_value = @current_quote_value
        @current_capital_position-=capital_investment
        self.number_of_evolution_trading_signals+=1
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
    else
      # Generate Trading Signal Since
    end
  end

  def magnitude_of_change_since(millseconds_since)
    @quote_value_then = @quote_target.quote_values.get_one_by_time(@current_date_time-(millseconds_since/1000.0).seconds).ask
    Rails.logger.debug("Magnitude of change: then: #{@quote_value_then} current: #{@current_quote_value}")
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
    if @how_far_back_milliseconds < 120000.0 or
       @how_far_back_milliseconds > (1000*60*MAXIMUM_MINUTES_BACK).to_f or
       @open_magnitude_signal_trigger < -1000.0 or
       @open_magnitude_signal_trigger > 1000.0 or
       @close_magnitude_signal_trigger < -1000.0 or
       @close_magnitude_signal_trigger > 1000.0
      true
    else
      false
    end
  end

  def fitness(quote_target, start_date,end_date,trading_signals_min,trading_signals_max)
    @quote_target = quote_target
    setup_parameters
    if out_of_range_attributes?
      FAILED_FITNESS_VALUE
    else
      @evolution_mode = true
      @current_position_units = nil
      @last_opened_position_value = nil
      @current_capital_position = @start_capital_position = DEFAULT_START_CAPITAL
      @from_hour = trading_strategy_set.trading_time_frame.from_hour
      @to_hour = trading_strategy_set.trading_time_frame.to_hour
      number_of_evolution_trading_signals = 0
      last_minute = false
      (start_date.to_date..end_date.to_date).each do |day|
        (@from_hour..@to_hour).each do |hour|
          (0..59).each do |minute|
            last_minute = (hour==@to_hour and minute==59) and TradingStrategySet::FORCE_RELEASE_POSITION
            evaluate(quote_target, DateTime.parse("#{day} #{hour}:#{minute}:00"), last_minute)
            break if last_minute
          end
          break if last_minute
        end
        break if last_minute
      end
      Rails.logger.debug("Number of trading signals: #{self.number_of_evolution_trading_signals}")
      if self.number_of_evolution_trading_signals<trading_signals_min or
         self.number_of_evolution_trading_signals>trading_signals_max
        self.simulated_fitness = FAILED_FITNESS_VALUE
      else
        self.simulated_fitness  = @current_capital_position-@start_capital_position
      end
      self.save
      self.simulated_fitness
    end
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
