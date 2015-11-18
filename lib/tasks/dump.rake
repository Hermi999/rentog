# on production:  RAILS_ENV=production FILE=/tmp/dump_production.sql.gz STAGING_IP=172.31.13.175 rake dump:export
# on staging:     RAILS_ENV=staging FILE=/tmp/dump_production.sql.gz rake dump:barrier maintenance:enable db:drop db:create dump:import db:migrate maintenance:restart maintenance:disable


require 'erb'
require 'yaml'

namespace :dump do
  desc "Fails if FILE doesn't exists"
  task :barrier do
    file = ENV['FILE']
    raise "Need a FILE" unless file

    File.exists?(file) or raise "No file found (path given by FILE)"
  end

  task :barrier do
    file = ENV['FILE']
    raise "Need a FILE" unless file
  end

  desc "Export the database"
  task :export do
    file = ENV['FILE']
    raise "Need a FILE" unless file

    env = ENV['RAILS_ENV']
    raise "Need a RAILS_ENV" unless env

    staging_ip = ENV['STAGING_IP']
    raise "Need a STAGING_IP" unless staging_ip

    db_config = current_db_config(env)
    system "#{mysqldump(db_config)} | gzip -c > #{file}"

    # wah: transfer file from production to staging server
    # scp -i ~/Path-To-Key-File/AAA.pem /path/file  ec2-user@<Private IP of Machine B>:/path/file
    # Allow SSH Inbound on staging server
    # system "scp -i ~/ec2key-Frankfurt.pem /tmp/dump_production.sql.gz ec2-user@172.31.13.175:/tmp/dump_production.sql.gz"
    system "scp -i ~/ec2key-Frankfurt.pem #{file} ec2-user@#{staging_ip}:#{file}"
  end

  desc "Import a database"
  task :import => :barrier do
    file = ENV['FILE']
    raise "Need a FILE" unless file

    env = ENV['RAILS_ENV']
    raise "Need a RAILS_ENV" unless env
    raise "Import on production is forbidden" if env == "production"

    db_config = current_db_config(env)
    system "gzip -d -c #{file} | #{mysql(db_config)}"
  end

  def current_db_config(env)
    YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../../config/database.yml'))).result)[env]
  end

  def mysql(config)
    sql_cmd('mysql', config)
  end

  def mysqldump(config)
    sql_cmd('mysqldump', config) + " --add-drop-table --extended-insert=TRUE --disable-keys --complete-insert=FALSE --triggers=FALSE"
  end

  def sql_cmd(sql_command, config)
    "".tap do |cmd|
      cmd << sql_command
      cmd << " "
      cmd << "-u#{config['username']} " if config['username']
      cmd << "-p#{config['password']} " if config['password']
      cmd << "-h#{config['host']} " if config['host']
      cmd << "-P#{config['port']} " if config['port']
      cmd << "--default-character-set utf8 "
      cmd << config['database'] if config['database']
    end
  end
end
