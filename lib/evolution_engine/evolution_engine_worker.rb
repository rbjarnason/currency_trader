require 'rubygems'
require 'daemons'
require 'yaml'

f = File.open( File.dirname(__FILE__) + '/config/worker.yml')
worker_config = YAML.load(f)

ENV['RAILS_ENV'] = worker_config['rails_env']

options = {
    :app_name   => "evolution_engine_worker_"+ENV['RAILS_ENV'],
    :dir_mode   => :script,
    :backtrace  => true,
    :monitor    => false,
    :log_output => true,
    :script     => "evolution_engine_worker_daemon.rb"
  }

Daemons.run(File.join(File.dirname(__FILE__), 'evolution_engine_worker_daemon.rb'), options)
