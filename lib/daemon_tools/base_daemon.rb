# encoding: UTF-8

require 'rubygems'
require 'yaml'
require 'daemons'
require 'rubygems'
require 'sys/filesystem'
require File.dirname(__FILE__) + '/../../config/boot'
require File.dirname(__FILE__) + '/../../config/environment'
#require "#{Rails.root}/config/environment"
require File.dirname(__FILE__) + '/../utils.rb'

include Sys

FILESYSTEM_TO_TEST = "/"

MASTER_TEST_MAX_COUNTER = 50000
MIN_FREE_SPACE_GB = 1
SLEEP_WAITING_FOR_FREE_SPACE_TIME = 120
SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN = 120
SLEEP_WAITING_FOR_DAEMONS_TO_END = 120
SLEEP_WAITING_BETWEEN_RUNS = 2
SQL_RESET_TIME_SEC = 120

EMAIL_REPORTING_INTERVALS = 7200
SELLERS_DETECTION_THRESHOLD = 0.0
MAX_NUMBER_OF_DEAMONS = 1

class Array
  def random(weights=nil)
    return random(map {|n| n.send(weights)}) if weights.is_a? Symbol
    weights ||= Array.new(length, 1.0)
    total = weights.inject(0.0) {|t,w| t+w}
    point = rand * total
   
    zip(weights).each do |n,w|
    return n if w >= point
      point -= w
    end
  end
end

config = YAML::load(File.open(File.dirname(__FILE__) + "/../../config/database.yml"))

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(config[ENV['RAILS_ENV']])
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "mail.streamburst.co.uk",
  :port => 25,
  :domain => "streamburst.tv",
   :authentication => :login,
   :user_name => "robert@streamburst.co.uk",
   :password => "runner44"
}

class BaseDaemonWorker

  public

  def initialize(config, logger)
    @logger = logger
    @shell = Shell.new(self)
    @worker_config = config
    @counter = 0
    @last_report_time = 0
  end

  def log_time
    t = Time.now
    "%02d/%02d %02d:%02d:%02d.%06d" % [t.day, t.month, t.hour, t.min, t.sec, t.usec]
  end

  def info(text)
    @logger.info("cs_info %s: %s" % [log_time, text])
  end

  def warn(text)
    @logger.warn("cs_warn %s: %s" % [log_time, text])
  end

  def error(text)
    @logger.error("cs_error %s: %s" % [log_time, text])
    #TODO: SEND ADMIN EMAIL
  end

  def debug(text)
    @logger.debug("cs_debug %s: %s" % [log_time, text])
    puts "cs_debug %s: %s" % [log_time, text]
  end
  
  def load_avg
    results = ""
    IO.popen("cat /proc/loadavg") do |pipe|
      pipe.each("\r") do |line|
        results = line
        #$defout.flush
      end
    end
    results.split[0..2].map{|e| e.to_f}
  end

  def check_load_and_wait
    loop do
      break if load_avg[0] < @worker_config["max_load_average"]
      info("Load Average #{load_avg[0]}, #{load_avg[1]}, #{load_avg[2]}")      
      info("Load average too high pausing for #{SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN}")
      sleep(SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN)
    end
  end

  def email_progress_report(freeGB)
    info("emailing report")
    begin
      report = AdminMailer.create_report("#{self.class.to_s} Unit #{@worker_config['server_id']} Reporting",
       "Free Space in GB #{freeGB} - Run count: #{@counter}\n\nLoad Average #{load_avg[0]}, #{load_avg[1]}, #{load_avg[2]}")
      report.set_content_type("text/html")
      AdminMailer.deliver(report)
    rescue => ex
      error(ex)
      error(ex.backtrace)
    end
    #TODO: Add time of email
  end

  def run
    info("Starting loop")
    @daemon_count = 0
    @daemons = []
    loop do
      stat = Filesystem.stat(FILESYSTEM_TO_TEST)
      freeGB = (stat.block_size * stat.blocks_available) /1024 / 1024 / 1024
      if @last_report_time+EMAIL_REPORTING_INTERVALS<Time.now.to_i
        email_progress_report(freeGB) unless ENV['RAILS_ENV']=="development"
        @last_report_time = Time.now.to_i
      end
      info("Free space in GB #{freeGB} - Run count: #{@counter}")
      info("Load Average #{load_avg[0]}, #{load_avg[1]}, #{load_avg[2]}")      
      if load_avg[0] < @worker_config["max_load_average"]
        if freeGB > MIN_FREE_SPACE_GB
          if 1==2 and ENV['RAILS_ENV'] == 'development' && @counter > MASTER_TEST_MAX_COUNTER
            warn("Reached maximum number of test runs - sleeping for an hour")
            sleep(3600)
          else
            @counter = @counter + 1
            begin
              poll_for_work
            rescue => ex
              error("Problem with paragraph worker")
              error(ex)
              error(ex.backtrace)
            end
          end
          info("Sleeping for #{SLEEP_WAITING_BETWEEN_RUNS} sec")
          sleep(SLEEP_WAITING_BETWEEN_RUNS)
        else
          info("No more space on disk - sleeping for #{SLEEP_WAITING_FOR_FREE_SPACE_TIME} sec")
          sleep(SLEEP_WAITING_FOR_FREE_SPACE_TIME)
        end
      else
        info("Load average too high at: #{load_avg[0]} - sleeping for #{SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN} sec")
        sleep(SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN)
      end
    end
    puts "THE END"
  end
end
