require 'csv'
namespace :ops do

  desc "Setup test"
  task :setup_test => :environment do

    acct = TradingAccount.new
    acct.save

    pop = TradingStrategyPopulation.first
    operation = TradingOperation.new
    operation.trading_strategy_population = pop
    operation.trading_account = TradingAccount.last
    operation.initial_capital_amount = 10000000
    operation.current_capital = 10000000
    operation.last_processing_time = DateTime.now-1.hour
    operation.processing_time_interval = 30
    operation.quote_target = pop.quote_target
    operation.save
  end


  desc "Reset"
  task :reset => :environment do
    TradingAccount.delete_all
    TradingOperation.delete_all
    TradingSignal.delete_all
    TradingPosition.delete_all
  end
end
