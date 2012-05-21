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
  TradingStrategyPopulation.delete_all
  TradingStrategySet.delete_all
  TradingStrategy.delete_all
  pop=TradingStrategyPopulation.new
  pop.active = true
  pop.quote_target = QuoteTarget.last
  pop.in_process = true
  pop.max_generations = 2000000
  pop.population_size = 150
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
  operation = TradingOperation.new
  operation.trading_strategy_population = TradingStrategyPopulation.last
  operation.trading_account = acct
  operation.initial_capital_amount = 10000000
  operation.current_capital = 10000000
  operation.last_processing_time = DateTime.now-1.hour
  operation.processing_time_interval = 45
  operation.quote_target = QuoteTarget.where("symbol='EUR/USD'").first
  operation.save

end
