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
      quote_value.import_csv_data(@logger,quote_data)
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


  def poll_for_yahoo_quote_work
    info("poll_for_quote_work")
    @quote_target = QuoteTarget.find(:first, :conditions => "active = 1 AND yahoo_quote_enabled = 1 AND last_yahoo_processing_time < NOW() - processing_time_interval", :lock => true)
    if @quote_target
      @quote_target.last_yahoo_processing_time = Time.now+1.hour
      @quote_target.save
      process_yahoo_quote_target
    end
  end

  def poll_for_work
    debug("poll_for_work")
    process_truefx_quote_values
    sleep 15
  end
end

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

crawler_worker = CrawlerWorker.new(worker_config, Rails.logger = Logger.new( File.join(File.dirname(__FILE__), "crawler_worker_#{ENV['RAILS_ENV']}.log")))
crawler_worker.run
