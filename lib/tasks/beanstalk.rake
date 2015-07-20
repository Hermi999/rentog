# Thanks to Trevor Turk (http://trevorturk.com/2009/06/25/config-vars-and-heroku/)
# wah: Be aware that with (...if val) only those configurations are loaded which
# are not 'false'.
# That means if a konfiguration is changed from value true to false in the
# config.yml file, the configuration isn't loaded with the command
# 'rake elasticbeanstalk:config' & on Elastic Beanstalk the env var will still
# be set to true
#
# This could be fixed with '...if !val.nil?...' but there was a problem with
# the param "always_use_ssl"
#
namespace :beanstalk do
  desc "Create ENV-VARs from config.yml file and upload them to Beanstalk"
  task :config do
    puts "Reading config/config.yml and sending PRODUCTION config vars to Beanstalk..."
    CONFIG = YAML.load_file('config/config.yml')['production'] rescue {}
    command = "eb setenv"
    CONFIG.each {|key, val|
      command << " #{key}=#{val} " if val
      }
    puts command
    system command
  end

  desc "Print all ENV-Vars which are generated from config.yml file"
  task :printEnvVars do
    puts "Reading config/config.yml..."
    CONFIG = YAML.load_file('config/config.yml')['production'] rescue {}
    command = ""
    CONFIG.each {|key, val|
      command << " #{key}=#{val}\n" if val
      }
    puts command
  end
end
