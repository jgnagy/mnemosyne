# A generic way of constructing a mergeable configuration
class Mnemosyne::Config < OpenStruct
  # Construct a base config using the following order of precedence:
  #   * environment variables
  #   * YAML file
  #   * defaults
  def load
    # First, apply the defaults
    defaults = {
      region: 'us-east-1'
    }
    merge defaults

    # Then apply the config file, if one exists
    apprc_dir = File.expand_path(File.join('~', '.mnemosyne'))
    config_file = File.expand_path(File.join(apprc_dir, 'config.yml'))

    merge YAML.load_file(config_file) if File.readable?(config_file)

    # Finally, apply any environment variables specified
    env_conf = {}
    defaults.keys.each do |key|
      env_key = "MNEMOSYNE_#{key}".upcase
      env_conf[key] = ENV[env_key] if ENV.key?(env_key)
    end
    merge env_conf unless env_conf.empty?
  end

  def merge(data)
    raise Exceptions::InvalidConfigData unless data.is_a?(Hash)
    data.each do |k, v|
      self[k.to_sym] = v
    end
  end
end

# Make the config available as a singleton
module Mnemosyne
  class << self
    def config
      @config ||= Config.new
    end
  end
end
