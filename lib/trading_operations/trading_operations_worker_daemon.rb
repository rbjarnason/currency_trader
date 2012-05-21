# encoding: UTF-8
require "net/http"

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "#{File.expand_path(File.dirname(__FILE__))}/../daemon_tools/base_daemon.rb"

class TradingOperationsWorker < BaseDaemonWorker
  def poll_for_trading_operations
    @operation = TradingOperation.where("active = 1 AND last_processing_time < NOW() - processing_time_interval").lock(true).order('rand()').first
    if @operation
      @operation.last_processing_time = Time.now
      @operation.save
      @operation.trading_positions.where("open=1").each do |position|
        position.trading_strategy.evaluate(@set.population.quote_target,DateTime.now,false,@operation.id,position.id)
      end
      @set = @operation.trading_strategy_population.best_set
      positions_left_to_open = @operation.trading_strategy_population.simulation_number_of_trading_strategies_per_set-@operation.trading.positions.count
      if @set and positions_left_to_open>0
        strategies = @set.trading_strategies.order("rand()")
        strategies[0..positions_left_to_open].each do |strategy|
          strategy.evaluate(@set.population.quote_target,DateTime.now,false,@operation.id)
        end
      end
    end
  end

  def process_short_open
    capital_investment = TradingStrategy::DEFAULT_POSITION_UNITS*@signal.current_quote_value
    #if @operation.capital_position>capital_investment
    position = TradingPosition.new
    position.units = TradingStrategy::DEFAULT_POSITION_UNITS
    position.value_open = @signal.open_quote_value # GET THE REALTIME
    position.open = true
    position.trading_operation = @operation
    position.trading_strategy = @signal.trading_strategy.id
    position.save
    @operation.current_capital-=capital_investment
  end

  def process_short_close
    position = @signal.trading_position.lock(true)
    shorted_at = position.value_open * position.position.units
    currently_at = @signal.close_quote_value * position.units # GET THIS REALTIME
    difference = shorted_at-currently_at
    position.value_close = @signal.close_quote_value
    position.profit_loss = difference
    position.open = false
    position.save
    @operation.current_capital+=shorted_at+difference
    @signal.profit_loss = difference
  end

  def poll_for_trading_signals
    @signal = TradingSignal.where("complete = 0").lock(true).first
    @operation = signal.trading_operation.lock(true)
    if signal.name=="Short Open"
      process_short_open
    elsif signal.name=="Short Close"
      process_short_close
    end
    @signal.complete = 1
    @signal.save
    @operation.save
  end

  def poll_for_work
    debug("poll_for_work")
    poll_for_trading_operations
    50.times { poll_for_trading_signals }
  end
end

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

crawler_worker = TradingOperationsWorker.new(worker_config, Logger.new( File.join(File.dirname(__FILE__), "trading_operations#{ENV['RAILS_ENV']}.log")))
crawler_worker.run
