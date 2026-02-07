# frozen_string_literal: true

require "yaml"

module Herb
  module Config
    # Loads configuration from .herb.yml files.
    module Loader
      # Default configuration file name
      CONFIG_FILE_NAME = ".herb.yml"

      # Loads configuration from .herb.yml using the following search order:
      # 1. Explicit path: parameter (error if not found) - mapped from --config-file CLI option
      # 2. HERB_CONFIG environment variable
      # 3. Upward directory traversal from Dir.pwd
      # 4. Default configuration (if HERB_NO_CONFIG not set)
      #
      # @rbs path: String? -- explicit path to configuration file (from --config-file)
      # @rbs validate: bool -- whether to validate configuration (default: true)
      def self.load(path: nil, validate: true) #: Hash[String, untyped]
        config_path = find_config_path(path:)

        config = if config_path
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

      # Finds configuration file path using search order.
      # @rbs path: String? -- explicit path
      def self.find_config_path(path: nil) #: String?
        # 1. Explicit path parameter
        if path
          return path if File.exist?(path)

          raise Error, "Configuration file not found: #{path}"
        end

        # 2. HERB_CONFIG environment variable
        herb_config = ENV.fetch("HERB_CONFIG", nil)
        if herb_config
          return herb_config if File.exist?(herb_config)

          raise Error, "Configuration file not found: #{herb_config} (from HERB_CONFIG)"
        end

        # 3. HERB_NO_CONFIG environment variable - skip search, use defaults
        return nil if ENV.fetch("HERB_NO_CONFIG", nil)

        # 4. Upward directory traversal from current directory
        search_upward(Dir.pwd)
      end

      # Searches upward from the given directory for a configuration file.
      # @rbs dir: String -- directory to start searching from
      def self.search_upward(dir) #: String?
        current_dir = File.expand_path(dir)
        root = File.expand_path("/")

        loop do
          config_path = File.join(current_dir, CONFIG_FILE_NAME)
          return config_path if File.exist?(config_path)

          # Stop at filesystem root
          break if current_dir == root

          # Move up one directory
          parent_dir = File.dirname(current_dir)
          break if parent_dir == current_dir # Safety check for edge cases

          current_dir = parent_dir
        end

        nil
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

      private_class_method :load_file, :find_config_path, :search_upward
    end
  end
end
