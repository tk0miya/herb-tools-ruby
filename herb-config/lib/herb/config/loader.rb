# frozen_string_literal: true

require "yaml"

module Herb
  module Config
    # Loads and parses .herb.yml configuration files.
    class Loader
      # Default configuration filename
      CONFIG_FILENAME = ".herb.yml" #: String

      # @rbs @explicit_path: String?
      # @rbs @working_dir: String

      # Initialize a new Loader
      # @rbs path: String? -- explicit path to configuration file
      # @rbs working_dir: String -- directory to search for configuration
      def initialize(path: nil, working_dir: Dir.pwd) #: void
        @explicit_path = path
        @working_dir = working_dir
      end

      # Load configuration from file and merge with defaults
      # @raise [FileNotFoundError] when explicit path is not found
      # @raise [ParseError] when YAML parsing fails
      def load #: Hash[String, untyped]
        config_path = find_config_path

        if config_path
          user_config = load_from_file(config_path)
          Defaults.merge(user_config)
        else
          Defaults.config
        end
      end

      # Locate configuration file path
      def find_config_path #: String?
        explicit_path = @explicit_path
        if explicit_path
          raise FileNotFoundError, "Configuration file not found: #{explicit_path}" unless File.exist?(explicit_path)

          return explicit_path
        end

        env_path = ENV.fetch("HERB_CONFIG", nil)
        if env_path
          raise FileNotFoundError, "Configuration file not found: #{env_path}" unless File.exist?(env_path)

          return env_path
        end

        search_upward(@working_dir)
      end

      private

      # Search for configuration file in directory and parent directories
      # @rbs dir: String
      def search_upward(dir) #: String?
        current = File.expand_path(dir)

        loop do
          config_path = File.join(current, CONFIG_FILENAME)
          return config_path if File.exist?(config_path)

          parent = File.dirname(current)
          break if parent == current

          current = parent
        end

        nil
      end

      # Load and parse YAML from file
      # @rbs path: String
      def load_from_file(path) #: Hash[String, untyped]
        content = File.read(path)
        parse_yaml(content, path)
      end

      # Parse YAML content safely
      # @rbs content: String
      # @rbs path: String
      def parse_yaml(content, path) #: Hash[String, untyped]
        result = YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)

        case result
        when Hash
          result
        when nil
          {}
        else
          raise ParseError, "Invalid configuration in #{path}: expected a hash, got #{result.class}"
        end
      rescue Psych::SyntaxError => e
        raise ParseError, "Invalid YAML in #{path}: #{e.message}"
      end
    end

    # Raised when configuration file is not found
    class FileNotFoundError < Error; end

    # Raised when YAML parsing fails
    class ParseError < Error; end
  end
end
