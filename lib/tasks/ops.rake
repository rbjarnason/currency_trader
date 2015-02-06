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
    operation.initial_capital_amount = 1000000
    operation.current_capital = 1000000
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
  
  desc "Export quotes"
  task :export_quotes  => :environment do
    puts "DateTime,Ask,High,Low,Open"
    QuoteValue.where("quote_target_id = 1 AND created_at >= :start_date AND created_at <= :end_date", {:start_date => DateTime.now-3.years, :end_date => DateTime.now-(1.years+6.months)}).limit(100000).order("data_time DESC").each do |q|
      puts "#{q.data_time},#{q.ask},#{q.high},#{q.low},#{q.open}"
    end  
  end
end
