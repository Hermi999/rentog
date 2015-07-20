require 'yaml'
require 'ostruct'

module ConfigLoader
  DEFAULT_CONFIGS = "/config/config.defaults.yml"
  USER_CONFIGS = "/config/config.yml"

  module_function

  # Load configurations in order:
  # - default
  # - user
  # - env
  #
  # User configs override default configs and env configs override both user and default configs
  def load_app_config
    default_configs = read_yaml_file(DEFAULT_CONFIGS)
    user_configs = read_yaml_file(USER_CONFIGS)
    environment_configs = Maybe(ENV).or_else({})

    # Order: default, user, env
    config_order = [default_configs, user_configs, environment_configs]
    configs = config_order.inject { |a, b| a.merge(b) }

    # In opposite to the yaml-files, we get by reading the Env-Vars,
    # always Strings instead of booleans if there are 'true' or 'false' values
    # But to make sure, we perform the test with all of the vars
    configs.each do |key, val|
      configs[p key] = true if val == "true"
      configs[p key] = false if val == "false"
    end

    OpenStruct.new(configs.symbolize_keys)
  end

  def read_yaml_file(file)
    abs_path = "#{Rails.root}/#{file}"
    file_content = if File.exists?(abs_path)
      YAML.load_file(abs_path)[Rails.env]
    end

    Maybe(file_content).or_else({})
  end
end
