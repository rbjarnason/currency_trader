# encoding: UTF-8
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "#{File.expand_path(File.dirname(__FILE__))}/../daemon_tools/base_daemon.rb"

class EvolutionEngineWorker < BaseDaemonWorker
  def process_evolution_target
    debug("process_evolution_target")
    begin
      @trading_strategy_set.calculate_fitness
    rescue => ex
      Rails.logger.error("Error processing Set! #{ex} #{ex.backtrace}")
      @trading_strategy_set.error_flag = 1
    end
    @trading_strategy_set.in_process = false
    @trading_strategy_set.complete = true
    @trading_strategy_set.archived = true
    @trading_strategy_set.last_processing_stop_time = Time.now
    @trading_strategy_set.save
    debug("FITNESS FOR SET: #{@trading_strategy_set.fitness}")
  end

  def poll_for_trading_strategy_set_work
    Rails.logger.info("Poll for_trading strategies work")
    @trading_strategy_set = TradingStrategySet.find(:first, :conditions => "active = 1 AND in_process = 0 AND complete = 0 AND error_flag = 0", :order => 'rand()', :lock=>true)
    if @trading_strategy_set and @trading_strategy_set.complete = 0 and @trading_strategy_set.in_process = 0 and @trading_strategy_set.error_flag = 0
      Rails.logger.info("Processing strategy set: #{@trading_strategy_set.id}")
      @trading_strategy_set.in_process = 1
      @trading_strategy_set.last_work_unit_time = 0
      @trading_strategy_set.last_processing_start_time = Time.now
      @trading_strategy_set.save
      @trading_strategy_set.reload(:lock => true)
      process_evolution_target
      Rails.logger.info("Complete: Processing strategy set")
    elsif not @trading_strategy_set
      sleep_amount = 2
      Rails.logger.info("Sleeping for #{sleep_amount} seconds")
      sleep sleep_amount
    end
  end

  def process_population_target
    @population.evolve
    @population.last_processing_stop_time = Time.now
    @population.in_process = 1 
    @population.save
  end

  def poll_for_evolution_work
    Rails.logger.info("Poll_for_evolution_work")
    TradingStrategyPopulation.transaction do
      @population = TradingStrategyPopulation.where("active = 1 AND complete = 0 AND in_process = 1").order('rand()').lock(true).first
      if @population and @population.is_generation_testing_complete?
        if not @population.complete and @population.active and @population.in_process and @population.is_generation_testing_complete?
          @population.last_processing_start_time = Time.now
          @population.in_process = false
          @population.save
          @population.reload(:lock => true)
        end
      end
    end
    if @population and not @population.complete and @population.active and not @population.in_process and @population.is_generation_testing_complete?
      process_population_target
      Rails.logger.info("Complete: Poll_for_evolution_work")
    end
  end

  def poll_for_work
    if @worker_config["only_populations"]
      poll_for_evolution_work
      sleep 1
    else
      poll_for_trading_strategy_set_work
    end
  end
end

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

EvolutionEngineWorker.new(worker_config, Rails.logger = Logger.new( File.join(File.dirname(__FILE__), "evolution_engine_worker_#{ENV['RAILS_ENV']}.log"))).run
