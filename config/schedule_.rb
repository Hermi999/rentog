# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 1.minute do
  command "cd /var/app/current && bundle exec ensure_one_cron_leader"
end



# on production:  RAILS_ENV=production FILE=/tmp/dump_production.sql.gz STAGING_IP=172.31.13.175 rake dump:export
# on staging:     RAILS_ENV=staging FILE=/tmp/dump_production.sql.gz rake dump:barrier maintenance:enable db:drop db:create dump:import db:migrate maintenance:restart maintenance:disable

set :production_dump_file, '/tmp/production_dump_daily.sql.gz'
set :staging_dump_file, '/tmp/production_dump_daily.sql.gz'
set :staging_ip, '172.31.13.175'

if environment == 'production' || environment == 'staging'
  # normal crons goes here
end

if environment == 'production'
  # Export daily dump
  every :day, :at => '02:00am', :roles => [:leader] do
    command "cd #{path} && #{environment_variable}=#{environment} FILE=#{production_dump_file} STAGING_IP=#{staging_ip} rake dump:export"
  end
end

if environment == 'staging'
  # Import daily dump
  every :day, :at => '02:30am', :roles => [:leader] do
    command "cd #{path} && #{environment_variable}=#{environment} FILE=#{staging_dump_file} rake dump:barrier maintenance:enable db:drop db:create dump:import db:migrate maintenance:restart maintenance:disable"
  end
end
