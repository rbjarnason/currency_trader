namespace :utils do
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
