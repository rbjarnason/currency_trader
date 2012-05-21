# encoding: UTF-8
require "net/http"

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "#{File.expand_path(File.dirname(__FILE__))}/../daemon_tools/base_daemon.rb"

class TradingOperationsWorker < BaseDaemonWorker
  def poll_for_trading_operations
    @operation = TradingOperation.where("active = 1 AND last_processing_time < NOW() - processing_time_interval").lock(true).order('rand()').first
    if @operation
      @operation.last_processing_time = Time.now+1.hour
      @operation.save
      @set = @operation.trading_strategy_population.best_set
      #positions_left_to_open = @operation.trading_strategy_population.simulation_number_of_trading_strategies_per_set-@operation.trading_positions.where("open=1").count
      if @set and not @set.trading_strategies.empty?
        @set.trading_strategies.each do |strategy|
          unless @operation.trading_positions.where(["open=1 AND trading_strategy_id=?",strategy.id]).first
            info("DateTime-1.hour!!! About to evaluate #{strategy.id} #{@set.id} #{@set.population.quote_target.symbol}")
            strategy.evaluate(@set.population.quote_target,DateTime.now,false,@operation.id)
          end
        end
      end
      @operation.trading_positions.where("open=1").each do |position|
        info("Checking position #{position.id}")
        position.trading_strategy.evaluate(@set.population.quote_target,DateTime.now,false,@operation.id,position.id)
      end
    end
  end

  def process_short_open
    info("process_short_open")
    capital_investment = TradingStrategy::DEFAULT_POSITION_UNITS*@signal.open_quote_value
    #if @operation.capital_position>capital_investment
    position = TradingPosition.new
    position.units = TradingStrategy::DEFAULT_POSITION_UNITS
    position.value_open = @signal.open_quote_value # GET THE REALTIME
    position.open = true
    position.trading_operation = @operation
    position.trading_strategy = @signal.trading_strategy
    position.save
    @operation.current_capital-=capital_investment
  end

  def process_short_close
    info("process_short_close")
    position = @signal.trading_position
    position.reload(:lock=>true)
    shorted_at = position.value_open * position.units
    currently_at = @signal.close_quote_value * position.units # GET THIS REALTIME
    difference = shorted_at-currently_at
    position.value_close = @signal.close_quote_value
    position.profit_loss = difference
    position.open = false
    position.save
    @operation.current_capital +=currently_at
    @signal.profit_loss = difference
  end

  def poll_for_trading_signals
    @signal = TradingSignal.where("complete = 0").lock(true).first
    if @signal
      @operation = @signal.trading_operation
      @operation.reload(:lock=>true)
      if @signal.name=="Short Open"
        process_short_open
      elsif @signal.name=="Short Close"
        process_short_close
      end
      @signal.complete = 1
      @signal.save
      @operation.save
    end
  end

  def poll_for_work
    debug("poll_for_work")
    poll_for_trading_operations
    50.times { poll_for_trading_signals }
    sleep 2
  end
end

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

crawler_worker = TradingOperationsWorker.new(worker_config, Logger.new( File.join(File.dirname(__FILE__), "trading_operations#{ENV['RAILS_ENV']}.log")))
crawler_worker.run
