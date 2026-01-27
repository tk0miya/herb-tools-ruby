# frozen_string_literal: true

module Herb
  module Config
    # Provides access to linter-specific configuration.
    class LinterConfig
      # Valid severity levels
      SEVERITY_LEVELS = %w[error warn warning info hint off].freeze #: Array[String]

      # Alias mapping for severity levels
      SEVERITY_ALIASES = {
        "warning" => "warn"
      }.freeze #: Hash[String, String]

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
        rule_config = rules[rule_name]
        return nil if rule_config.nil?

        severity = extract_severity(rule_config)
        normalize_severity(severity)
      end

      # Returns the options for a specific rule.
      # Returns an empty hash if no options are configured.
      # @rbs rule_name: String -- the name of the rule
      def rule_options(rule_name) #: Hash[String, untyped]
        rule_config = rules[rule_name]
        return {} if rule_config.nil?
        return {} unless rule_config.is_a?(Hash)

        rule_config["options"] || {}
      end

      private

      attr_reader :config #: Hash[String, untyped]

      def linter_config #: Hash[String, untyped]
        config["linter"] || {}
      end

      # @rbs rule_config: String | Hash[String, untyped]
      def extract_severity(rule_config) #: String?
        case rule_config
        when String
          rule_config
        when Hash
          rule_config["severity"]
        end
      end

      # @rbs severity: String?
      def normalize_severity(severity) #: String?
        return nil if severity.nil?

        SEVERITY_ALIASES.fetch(severity, severity)
      end
    end
  end
end
