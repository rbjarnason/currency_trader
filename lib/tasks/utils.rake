require 'csv'

namespace :utils do
  desc "Import quote data and destroy old"
  task :import_quote_data_and_destroy_old => :environment do
    symbol = ENV['symbol']
    clear_upto_date = DateTime.parse("01/06/2012 17:00") # #(Date.today-1).to_date.to_datetime+6.hours
    QuoteValue.transaction do
      quote_target = QuoteTarget.find_by_symbol(symbol)
      QuoteValue.where(["quote_target_id = ? AND data_time <= ?",quote_target.id, clear_upto_date]).destroy_all
      CSV.open("/home/robert/quote_data.csv").each do |quote|
        next if quote[0]=="SYMBOL"
        quote_target = QuoteTarget.where(:symbol=>quote[1].strip).first
        quote_value = QuoteValue.new
        quote_value.quote_target_id = quote_target.id
        puts quote[2]
        date_text = "#{quote[2][3..4]}/#{quote[2][0..1]}#{quote[2][5..100]}"
        quote_value.data_time = DateTime.parse(date_text)
        quote_value.timestamp_ms = quote_value.data_time.to_i
        quote_value.open = quote[3].to_f
        quote_value.high = quote[4].to_f
        quote_value.low = quote[5].to_f
        quote_value.ask = quote[6].to_f
        quote_value.save
        puts "#{quote_value.data_time} - #{quote_target.symbol} - #{quote_value.ask}"
      end
    end
  end

  desc "Disable enable range"
  task :disable_enable_range => :environment do
    TradingStrategyPopulation.where("id>=146 AND id<=149").all.each do |population|
      population.active = true
      population.save
      puts population
    end
    TradingStrategyPopulation.where("id>=162 AND id<=165").all.each do |population|
      population.active = false
      population.save
      puts population
    end
  end

    desc "Cleanup old stuff"
  task :cleanup_old_stuff => :environment do
    strategy_set_ids = []
    TradingStrategyPopulation.all.each do |population|
      strategy_set_ids << population.best_trading_strategy_set_id if population.best_trading_strategy_set_id
      population.active = false
      population.save
    end
    TradingStrategySet.where("id not in (?)",strategy_set_ids).destroy_all
  end

  desc "Dump database to tmp"
  task :dump_db => :environment do
    config = Rails.application.config.database_configuration
    current_config = config[Rails.env]
    abort "db is not mysql" unless current_config['adapter'] =~ /mysql/

    database = current_config['database']
    user = current_config['username']
    password = current_config['password']
    host = current_config['host']

    path = Rails.root.join("tmp","sqldump")
    base_filename = "#{ENV['name'] ? "#{ENV['name']}_" : ""}#{database}_#{Time.new.strftime("%d%m%y_%H%M%S")}.sql.gz"
    filename = path.join(base_filename)

    FileUtils.mkdir_p(path)
    command = "mysqldump --add-drop-table -u #{user} --password=#{password} #{database} | gzip > #{filename}"
    puts "Excuting #{command}"
    system command
  end
end
