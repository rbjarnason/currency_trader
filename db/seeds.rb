# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

timeframe = TradingTimeFrame.new
timeframe.from_hour = 01
timeframe.to_hour = 23
timeframe.save

pop = TradingStrategyPopulation.new
pop.save

set = TradingStrategySet.new
set.trading_strategy_population = pop
set.trading_time_frame = timeframe
set.save

temp = TradingStrategyTemplate.new
temp.name = "Test"
temp.save

t=TradingStrategy.new
t.trading_strategy_set=set
t.trading_strategy_template=temp
t.import_parameters({:float=>[20000.0,0.04,0.05], :binary=>[1,0]})
t.save

if false
  #TradingStrategyPopulation.delete_all
  #TradingStrategySet.delete_all
  #TradingStrategy.delete_all
  #TradingOperation.delete_all
  ##TradingSignal.delete_all
  TradingPosition.delete_all


  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 2000000
  pop.population_size = 700
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 4
  pop.simulation_end_date = DateTime.parse("18/05/2012 23:59:59")+1.day
  pop.simulation_min_overall_trading_signals = 2*4
  pop.simulation_max_overall_trading_signals = 10*4
  pop.simulation_max_daily_trading_signals = 20
  pop.simulation_max_minutes_back = 15
  pop.save
  pop.initialize_population
  pop.save
end

if false
  TradingOperation.delete_all
  TradingSignal.delete_all
  TradingPosition.delete_all
  TradingAccount.delete_all

  acct = TradingAccount.new
  acct.save

  pop = TradingStrategyPopulation.first
  operation = TradingOperation.new
  operation.trading_strategy_population_id = pop.id
  operation.trading_account = TradingAccount.last
  operation.initial_capital_amount = 10000000
  operation.current_capital = 10000000
  operation.last_processing_time = DateTime.now-1.hour
  operation.processing_time_interval = 30
  operation.quote_target_id = pop.quote_target.id
  operation.active = true
  operation.save

end

if false
  #TradingStrategyPopulation.delete_all
  #TradingStrategySet.delete_all
  #TradingStrategy.delete_all
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

  TradingStrategyPopulation.delete_all
  TradingStrategySet.delete_all
  TradingStrategy.delete_all
  TradingOperation.delete_all
  TradingSignal.delete_all
  TradingPosition.delete_all
  TradingTimeFrame.delete_all

  timeframe = TradingTimeFrame.new
  timeframe.from_hour = 00
  timeframe.to_hour = 23
  timeframe.save

  original_verbosity = $VERBOSE
  $VERBOSE = nil
  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  pop.in_process = true
  pop.max_generations = 200000000
  pop.population_size = 10
  pop.simulation_number_of_trading_strategies_per_set = 3
  pop.simulation_days_back = 11
  pop.simulation_min_overall_trading_signals = 2*pop.simulation_days_back
  pop.simulation_max_overall_trading_signals = 32*pop.simulation_days_back
  pop.simulation_max_daily_trading_signals = 32
  pop.simulation_max_minutes_back = 15
  pop.description = "Rolling 8 days back"
  pop.save
  pop.initialize_population
  $VERBOSE = original_verbosity
  pop.save
  pop.trading_strategy_sets.where_not_complete

  TradingStrategy.all.each do |x| puts x.inspect end
end