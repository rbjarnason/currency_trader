# encoding: UTF-8

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "#{File.expand_path(File.dirname(__FILE__))}/../daemon_tools/base_daemon.rb"

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

ENV['RAILS_ENV'] = worker_config['rails_env']

#FILESYSTEM_TO_TEST = "/var/content/evolution_engine_"+ENV['RAILS_ENV']+"/"
FILESYSTEM_TO_TEST = "/"

MASTER_TEST_MAX_COUNTER = 50000
MIN_FREE_SPACE_GB = 1
SLEEP_WAITING_FOR_FREE_SPACE_TIME = 120
SLEEP_WAITING_FOR_LOAD_TO_GO_DOWN = 120
SLEEP_WAITING_FOR_DAEMONS_TO_END = 120
SLEEP_WAITING_BETWEEN_RUNS = 1
SQL_RESET_TIME_SEC = 120

EMAIL_REPORTING_INTERVALS = 7200
SELLERS_DETECTION_THRESHOLD = 0.0
MAX_NUMBER_OF_DEAMONS = 1

require 'sys/filesystem'
include Sys

require File.dirname(__FILE__) + '/../utils/logger.rb'
require File.dirname(__FILE__) + '/../utils/shell.rb'

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

class EvolutionEngineWorker
  def initialize(config)
    @logger = Rails.logger
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
    Rails.logger.info("cs_info %s: %s" % [log_time, text])
  end

  def warn(text)
    Rails.logger.warn("cs_warn %s: %s" % [log_time, text])
  end

  def error(text)
    Rails.logger.error("cs_error %s: %s" % [log_time, text])
    #TODO: SEND ADMIN EMAIL
  end

  def debug(text)
    Rails.logger.debug("cs_debug %s: %s" % [log_time, text])
  end
  
  def process_evolution_target
    debug("process_evolution_target")
    begin
      @trading_strategy_set.calculate_fitness
    rescue => ex
      error("Error processing Set! #{ex} #{ex.backtrace}")
      @trading_strategy_set.error_flag = 1
    end
    @trading_strategy_set.in_process = 0
    @trading_strategy_set.complete = 1
    @trading_strategy_set.last_processing_stop_time = Time.now
    @trading_strategy_set.save
    debug("FITNESS FOR SET: #{@trading_strategy_set.fitness}")
  end

  def poll_for_trading_strategy_set_work
    debug("poll_for_trading_strategy_set_work")
#    TradingStrategySet.transaction do
      @trading_strategy_set = TradingStrategySet.find(:first, :conditions => "active = 1 AND in_process = 0 AND complete = 0 AND error_flag = 0", :order => 'rand()', :lock=>true)
      if @trading_strategy_set and @trading_strategy_set.complete = 0 and @trading_strategy_set.in_process = 0 and @trading_strategy_set.error_flag = 0
        debug("processing strategy set: #{@trading_strategy_set.id}")
        @trading_strategy_set.in_process = 1
        @trading_strategy_set.last_work_unit_time = 0
        @trading_strategy_set.last_processing_start_time = Time.now
        @trading_strategy_set.save
        @trading_strategy_set.reload(:lock => true)
        process_evolution_target
      end
#    end
  end

  def process_population_target
    @population.evolve
    @population.last_processing_stop_time = Time.now
    @population.in_process = 1 
    @population.save
  end

  def poll_for_evolution_work
    debug("poll_for_evolution_work")
    TradingStrategyPopulation.transaction do
      @population = TradingStrategyPopulation.find(:first, :conditions => "active = 1 AND complete = 0 AND in_process = 1", :order => 'rand()', :lock=>true)
      if @population and @population.is_generation_testing_complete?
        @population.last_processing_start_time = Time.now
        @population.in_process = 0
        @population.save
        @population.reload(:lock => true)
        process_population_target
     end
    end
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
    return
    info("emailing report")
    begin
      report = AdminMailer.create_report("Crawler Unit #{@worker_config['evolution_engine_server_id']} Reporting",
       "Free evolution_engine space in GB #{freeGB} - Run count: #{@counter}\n\nLoad Average #{load_avg[0]}, #{load_avg[1]}, #{load_avg[2]}")
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
      info("Free neural space in GB #{freeGB} - Run count: #{@counter}")
      info("Load Average #{load_avg[0]}, #{load_avg[1]}, #{load_avg[2]}")      
      if load_avg[0] < @worker_config["max_load_average"]
        if freeGB > MIN_FREE_SPACE_GB
          if 1==2 and ENV['RAILS_ENV'] == 'development' && @counter > MASTER_TEST_MAX_COUNTER
            warn("Reached maximum number of test runs - sleeping for an hour")
            sleep(3600)
          else
            @counter = @counter + 1
            begin
              poll_for_evolution_work
              poll_for_trading_strategy_set_work
            rescue => ex
              error("Problem with evolution_engine worker #{ex} #{ex.backtrace}")
            end
          end
          if SLEEP_WAITING_BETWEEN_RUNS > 0
            info("Sleeping for #{SLEEP_WAITING_BETWEEN_RUNS} sec")
            sleep(SLEEP_WAITING_BETWEEN_RUNS)
          end
        else
          info("No more space on disk for cache - sleeping for #{SLEEP_WAITING_FOR_FREE_SPACE_TIME} sec")
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

config = YAML::load(File.open(File.dirname(__FILE__) + "/../../config/database.yml"))
ENV['RAILS_ENV'] = worker_config['rails_env']

evolution_engine_worker = EvolutionEngineWorker.new(worker_config)
evolution_engine_worker.run

