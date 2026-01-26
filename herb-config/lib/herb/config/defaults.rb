# frozen_string_literal: true

module Herb
  module Config
    # Provides default configuration values and merging behavior.
    module Defaults
      # Default file patterns to include
      DEFAULT_INCLUDE = ["**/*.html.erb"].freeze #: Array[String]

      # Default file patterns to exclude
      DEFAULT_EXCLUDE = [].freeze #: Array[String]

      # Returns the complete default configuration
      def self.config #: Hash[String, untyped]
        {
          "linter" => {
            "include" => DEFAULT_INCLUDE.dup,
            "exclude" => DEFAULT_EXCLUDE.dup,
            "rules" => {}
          }
        }
      end

      # Merges user configuration with defaults
      # @rbs user_config: Hash[String, untyped]
      def self.merge(user_config) #: Hash[String, untyped]
        deep_merge(config, user_config)
      end

      # Deep merges two hashes recursively
      # @rbs base: Hash[String, untyped]
      # @rbs override: Hash[String, untyped]
      def self.deep_merge(base, override) #: Hash[String, untyped]
        base.merge(override) do |_key, base_val, override_val|
          if base_val.is_a?(Hash) && override_val.is_a?(Hash)
            deep_merge(base_val, override_val)
          else
            override_val
          end
        end
      end

      private_class_method :deep_merge
    end
  end
end
