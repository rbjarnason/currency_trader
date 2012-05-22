set :application, "currency_trader"
set :domain, "fx.decyphermedia.com"
set :scm, "git"
set :repository, "git@github.com:rbjarnason/currency_trader.git"
set :use_sudo, false
set :deploy_to, "/home/robert/sites/#{application}"
set :user, "robert"
set :deploy_via, :remote_cache
#set :shared_children, shared_children + %w[config db/sphinx assets]

set :shell, '/bin/bash'
default_run_options[:shell] = '/bin/bash'

role :app, domain
role :web, domain
role :db,  domain, :primary => true

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

after 'deploy:finalize_update' do
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/* #{current_release}/config/"
  run "ln -nfs #{deploy_to}/#{shared_dir}/system #{current_release}/public/system"
end

#after :deploy, "assets:precompile"