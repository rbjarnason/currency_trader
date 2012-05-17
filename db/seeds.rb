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
  TradingStrategyPopulation.destroy_all
  TradingStrategySet.destroy_all
  TradingStrategy.destroy_all
  pop=TradingStrategyPopulation.new
  pop.save
  pop.active = true
  pop.in_process = true
  pop.max_generations = 50
  pop.population_size = 100
  pop.initialize_population
  pop.save
end