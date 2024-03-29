require 'csv'

namespace :utils do
  desc "Cleanup signals"
  task :cleanup_signals => :environment do
    puts TradingSignal.count
    count = 0
    TradingSignal.all.each do |s|
      tp = TradingPosition.unscoped.where(:id=>s.trading_position_id).first
      unless tp or s.trading_position_id==nil
        count += 1
        puts "remove #{s.id} #{s.trading_position_id}"
      end
    end
    puts count
  end

  desc "Set positions amounts"
  task :set_positions_amounts => :environment do
    TradingPosition.all.each do |pos|
      pos.bought_amount=pos.value_open*pos.units
      if pos.value_close
        pos.sold_amount=pos.value_close*pos.units
      end
      pos.save
    end
  end

  desc "Import quote data"
  task :import_quotes => :environment do
    symbol = "EURUSD"
    puts "Delete complete"
    count = 0
    client = Elasticsearch::Client.new host: ES_HOST, log: false
    #client.indices.delete index: 'quotes-1'
    Dir.glob('/home/ubuntu/quote_data/*') do |item|
      puts item
      QuoteValue.transaction do
        CSV.open(item).each do |quote|
          next if quote[0]=="Time"
          client.create index: 'quotes-1',
                        type: 'quote',
                        body: {
                            symbol: symbol,
                            data_time: DateTime.parse(quote[0]),
                            timestamp_ms:  DateTime.parse(quote[0]).to_i,
                            open: quote[1].to_f,
                            high: quote[2].to_f,
                            low: quote[3].to_f,
                            close: quote[4].to_f,
                            ask: quote[1].to_f
                        }
          if count>3600
            puts "3600"
            count=0
          else
            count+=1
          end
        end
      end
    end
  end

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
    TradingStrategyPopulation.where("id>=146 AND id<=150 and active=1").order("rand()").all.each do |population|
      #population.reload(:lock=>true)
      population.active = false
      population.save
      puts population
    end
    TradingStrategyPopulation.where("id>=162 AND id<=165").lock(true).all.each do |population|
      population.active = true
      population.save
      puts population
    end
  end

  desc "Fix missing strategies"
  task :fix_missing_strategies => :environment do
    TradingPosition.where("open=1").all.each do |pos|
      unless pos.trading_strategy
        puts pos
        pos.trading_strategy = TradingStrategy.order("rand()").first
        pos.save
      end
    end
  end


  desc "Cleanup old stuff"
  task :cleanup_old_stuff => :environment do
    strategy_ids = []
    strategy_set_ids = []
    TradingStrategyPopulation.all.each do |population|
      strategy_set_ids << population.best_trading_strategy_set_id if population.best_trading_strategy_set_id
      population.trading_strategy_sets.order_by(:created_at => :desc).limit(70).each do |set|
        strategy_set_ids << set.id
      end

      population.trading_strategy_sets.order_by(:accumulated_fitness => :desc).limit(70).each do |set|
        strategy_set_ids << set.id
      end
    end

    strategy_set_ids.each do |set_id|
      TradingStrategySet.find(set_id).trading_strategies.each do |strategy|
        strategy_ids << strategy.id
      end
    end

    puts strategy_ids
    puts strategy_set_ids

    puts TradingStrategy.not_in(:_id=>strategy_ids.uniq).delete_all
    puts TradingStrategySet.not_in(:_id=>strategy_set_ids.uniq).delete_all
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
