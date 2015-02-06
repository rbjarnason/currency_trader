require 'csv'
if false
  TradingStrategyPopulation.delete_all
  TradingStrategySet.delete_all
  TradingStrategy.delete_all
  timeframe = TradingTimeFrame.new
  timeframe.from_hour = 00
  timeframe.to_hour = 23
  timeframe.save

  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 125
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 7
  pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.description = "Rolling 7 days back - no limits -100 stop"
  pop.save
  pop.initialize_population
  pop.save


  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 125
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 110
  pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.description = "Rolling 110 days back - no limits -100 stop"
  pop.save
  pop.initialize_population
  pop.save

  #pop=TradingStrategyPopulation.new
  #pop.active = true
  #pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 125
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 30
  pop.simulation_end_date = DateTime.parse("26/02/2012 17:59:59")
  pop.simulation_min_overall_trading_signals = 5*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 32*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.description = "Volatile but slow up trend - no limits -100 stop"
  pop.save
  pop.initialize_population
  pop.save

  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 125
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 4
  pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.description = "Rolling 4 days back - no limits -100 stop"
  pop.save
  pop.initialize_population
  pop.save

  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 125
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 45
  pop.simulation_end_date = DateTime.parse("10/04/2012 17:59:59")
  pop.simulation_min_overall_trading_signals = 1*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.description = "Volatile but down trend feb-apr  - no limits -100 stop"
  pop.save
  pop.initialize_population
  pop.save

  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 150
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 8
  pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 22*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 22
  pop.simulation_max_minutes_back = 15
  pop.description = "Rolling 8 days back"
  pop.save
  pop.initialize_population
  pop.save
end

namespace :evo do
  desc "Setup short test"
  task :cleanup_stalled => :environment do
    pop_id = ENV['pop_id']
    TradingStrategySet.where(:trading_strategy_population_id=>pop_id,:complete=>0, :in_population_process=>1).each do |set|
      set.in_process = false
      set.in_population_process=false
      set.complete = true
      set.accumulated_fitness=-9999
      set.save
    end
  end

  desc "Setup short test"
  task :t1 => :environment do
    pop=TradingStrategyPopulation.new
    pop.active = true
    pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
    pop.in_process = true
    pop.max_generations = 200000000
    pop.population_size = 25
    pop.simulation_number_of_trading_strategies_per_set = 3
    pop.simulation_days_back = 60
    pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
    pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
    pop.simulation_max_daily_trading_signals = 14
    pop.simulation_max_minutes_back = 59
    pop.description = "Rolling 60 days back"
    pop.stop_loss_enabled = true
    pop.save
    pop.initialize_population
    pop.save
  end

  desc "Setup long test"
  task :t2 => :environment do
    pop=TradingStrategyPopulation.new
    pop.active = true
    pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
    pop.in_process = true
    pop.max_generations = 200000000
    pop.population_size = 500
    pop.simulation_number_of_trading_strategies_per_set = 3
    pop.simulation_days_back = 60
    pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
    pop.simulation_max_overall_trading_signals = 14*pop.simulation_days_back
    pop.simulation_max_daily_trading_signals = 14
    pop.simulation_max_minutes_back = 42
    pop.description = "Rolling 60 days back"
    pop.stop_loss_enabled = true
    pop.save
    pop.initialize_population
    pop.save
  end

  desc "Reset"
  task :reset => :environment do
    TradingStrategyPopulation.delete_all
    TradingStrategySet.delete_all
    TradingStrategy.delete_all
  end


end
