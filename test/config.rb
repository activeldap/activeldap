require 'yaml'

def read_config
  config_file = File.join(File.dirname(__FILE__), "config.yaml")

  unless File.exist?(config_file)
    raise "config file for testing doesn't exist: #{config_file}"
  end
  YAML.load(File.read(config_file))
end
