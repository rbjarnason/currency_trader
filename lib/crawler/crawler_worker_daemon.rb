# encoding: UTF-8
require "net/http"
require 'csv'

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "#{File.expand_path(File.dirname(__FILE__))}/../daemon_tools/base_daemon.rb"

class CrawlerWorker < BaseDaemonWorker

  def process_yahoo_quote_target
    url = "http://download.finance.yahoo.com/d/quotes.csv?s=#{@quote_target.symbol[0..2]}#{@quote_target.symbol[4..6]}=X&f=l1&e=.csv"
    debug(url)
    raw_quote_data = Net::HTTP.get(URI.parse(url))
    debug(raw_quote_data)
    quote_data = raw_quote_data.split(",")
    if quote_data
      quote_value = QuoteValue.new
      quote_value.quote_target_id = @quote_target.id
      quote_value.data_time = DateTime.now
      quote_value.import_yahoo_csv_data(quote_data)
      quote_value.save
    end
  end

  def process_truefx_quote_values
    url_auth = "http://webrates.truefx.com/rates/connect.html?u=dave&p=detroit&q=myrates&f=csv"
    truefx_session_id = Net::HTTP.get(URI.parse(url_auth))
    url = "http://webrates.truefx.com/rates/connect.html?u=dave&p=detroit&q=myrates&f=csv&id=#{ CGI::escape(truefx_session_id.strip)}&s=n&c=#{QuoteTarget.all.collect {|t| t.symbol}.join(",")}"
    raw_quote_data = Net::HTTP.get(URI.parse(url))
    #debug(url)
    #debug(raw_quote_data)
    quote_data = CSV.parse(raw_quote_data.strip)
    quote_data.each do |quote|
      quote_target = QuoteTarget.where(:symbol=>quote[0]).first
      quote_value = QuoteValue.new
      quote_value.quote_target_id = quote_target.id
      quote_value.data_time = DateTime.now
      quote_value.import_csv_data(quote)
      quote_value.save
      Rails.logger.info "#{quote_target.symbol} - #{quote_value.ask}"
    end
  end

  def try_to_get_back_data
    url = "http://fxf.forexfeed.net/data?key=133850083068971&periods=600&interval=60&symbol=#{QuoteTarget.all.collect {|t| t.symbol.gsub("/","")}.join(",")}"
    raw_quote_data = Net::HTTP.get(URI.parse(url))
    puts raw_quote_data
    File.open("/home/robert/out.csv").write(raw_quote_data)
  end

  def process_forexfeed_quote_values
    url = "http://fxf.forexfeed.net/data?key=133850083068971&interval=60&symbol=#{QuoteTarget.all.collect {|t| t.symbol.gsub("/","")}.join(",")}"
    raw_quote_data = Net::HTTP.get(URI.parse(url))
#    raw_quote_data = "SYMBOL,TITLE,TIMESTAMP,OPEN,HIGH,LOW,CLOSE\n\"Status\",\"OK\"\n\"Version\",\"1.0\"\n\"Copyright\",\"ForexFeed\"\n\"Website\",\"http://forexfeed.net\"\n\"Redistribution\",\"REDISTRIBUTION OF CURRENCY DATA IS STRICTLY PROHIBITED BY LAW. The license Agreement only permits download of this data directly from forexfeed.net to a single Computer. CURRENCY DATA MAY NOT BE SHARED WITH OTHER Computers. You may use currency data in calculations involving other non-currency data and distribute the results but each Computer requiring currency data on its own requires separate licensing from forexfeed.net. For more information refer to your copy of the licence agreement or contact us at: tos@forexfeed.net\"\n\"License\",\"All use of this data is strictly regulated under the licensing Agreement. Unauthorized use or distribution is a violation of your legal duties and responsibilities.\"\n\"Access period\",\"day\"\n\"Permitted accesses per period\",\"1440\"\n\"Accesses so far this period\",\"1\"\n\"Accesses remaining in this period\",\"1439\"\n\"Access period began\",\"2012-06-01 02:17:54\",\"UTC\",\"0\",\"seconds ago\"\n\"Next access period begins\",\"2012-06-02 02:17:54\",\"UTC\",\"86400\",\"seconds from now\"\n\"UTC Time\",\"1338517074\"\n\"UTC Timestamp\",\"2012-06-01 02:17:54\"\n\"Data Interval\",\"60\"\nQUOTE START\nUSDEUR,USD/EUR,1338517020,0.81020,0.81020,0.81013,0.81013\nEURUSD,EUR/USD,1338517020,1.23426,1.23436,1.23426,1.23436\nAUDUSD,AUD/USD,1338517020,0.9675,0.9675,0.9674,0.9675\nUSDJPY,USD/JPY,1338517020,78.47,78.48,78.47,78.48\nQUOTE END\n" #Net::HTTP.get(URI.parse(url))

    #debug(url)
    #debug(raw_quote_data)
    quote_data = CSV.parse(raw_quote_data.strip)
    skip_until = true
    quote_data.each do |quote|
      puts quote.inspect
      if quote[0]=="QUOTE START"
        skip_until = false
        next
      end
      next if skip_until
      break if quote[0]=="QUOTE END"
      quote_target = QuoteTarget.where(:symbol=>quote[1].strip).first
      quote_value = QuoteValue.new
      quote_value.quote_target_id = quote_target.id
      quote_value.data_time = DateTime.now
      quote_value.timestamp_ms = quote[2].to_i
      quote_value.open = quote[3].to_f
      quote_value.high = quote[4].to_f
      quote_value.low = quote[5].to_f
      quote_value.ask = quote[6].to_f
      quote_value.save
      Rails.logger.info "#{quote_target.symbol} - #{quote_value.ask}"
    end
  end

  def poll_for_yahoo_quote_work
    info("poll_for_quote_work")
    @quote_target = QuoteTarget.find(:first, :order=>"rand()", :conditions => "active = 1 AND yahoo_quote_enabled = 1 AND last_yahoo_processing_time < NOW() - processing_time_interval", :lock => true)
    if @quote_target
      @quote_target.last_yahoo_processing_time = Time.now+1.hour
      @quote_target.save
      process_yahoo_quote_target
    end
  end

  def poll_for_work
    debug("poll_for_work")
    process_forexfeed_quote_values
    sleep 60
  end

  def poll_for_work_yahoo
    debug("poll_for_work")
    poll_for_yahoo_quote_work
    sleep 10
  end

end

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

crawler_worker = CrawlerWorker.new(worker_config, Rails.logger = Logger.new( File.join(File.dirname(__FILE__), "crawler_worker_#{ENV['RAILS_ENV']}.log")))
crawler_worker.run
