# frozen_string_literal: true

module Herb
  module Config
    # Provides access to linter-specific configuration.
    class LinterConfig
      # Valid severity levels (matches original TypeScript herb)
      SEVERITY_LEVELS = %w[error warning info hint].freeze #: Array[String]

      # @rbs config_hash: Hash[String, untyped] -- the full configuration hash
      def initialize(config_hash) #: void
        @config = config_hash
      end

      # Returns the file patterns to include in linting
      def include_patterns #: Array[String]
        linter_config["include"] || []
      end

      # Returns the file patterns to exclude from linting
      def exclude_patterns #: Array[String]
        linter_config["exclude"] || []
      end

      # Returns the rules configuration hash
      def rules #: Hash[String, untyped]
        linter_config["rules"] || {}
      end

      # Returns the severity for a specific rule.
      # Returns nil if the rule is not configured.
      # @rbs rule_name: String -- the name of the rule
      def rule_severity(rule_name) #: String?
        rules.dig(rule_name, "severity")
      end

      # Returns the options for a specific rule.
      # Returns an empty hash if no options are configured.
      # @rbs rule_name: String -- the name of the rule
      def rule_options(rule_name) #: Hash[String, untyped]
        rules.dig(rule_name, "options") || {}
      end

      private

      attr_reader :config #: Hash[String, untyped]

      def linter_config #: Hash[String, untyped]
        config["linter"] || {}
      end
    end
  end
end
