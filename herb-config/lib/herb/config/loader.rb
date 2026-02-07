# frozen_string_literal: true

require "yaml"

module Herb
  module Config
    # Loads configuration from .herb.yml files.
    module Loader
      # Default configuration file name
      CONFIG_FILE_NAME = ".herb.yml"

      # Loads configuration from .herb.yml in the specified directory.
      # Returns default configuration if file is not found.
      # @rbs dir: String -- directory to search for configuration file
      # @rbs validate: bool -- whether to validate configuration (default: true)
      def self.load(dir: Dir.pwd, validate: true) #: Hash[String, untyped]
        config_path = File.join(dir, CONFIG_FILE_NAME)

        config = if File.exist?(config_path)
                   load_file(config_path)
                 else
                   Defaults.config
                 end

        if validate
          validator = Validator.new(config)
          validator.validate!
        end

        config
      end

      # Loads configuration from a specific file path.
      # @rbs path: String -- path to the configuration file
      def self.load_file(path) #: Hash[String, untyped]
        content = File.read(path)
        user_config = YAML.safe_load(content) || {}

        raise Error, "Invalid configuration: expected a Hash, got #{user_config.class}" unless user_config.is_a?(Hash)

        Defaults.merge(user_config)
      rescue Psych::SyntaxError => e
        raise Error, "Invalid YAML in #{path}: #{e.message}"
      end

      private_class_method :load_file
    end
  end
end
