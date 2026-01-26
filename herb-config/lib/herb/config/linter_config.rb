# frozen_string_literal: true

module Herb
  module Config
    # Provides convenient access to linter-specific configuration.
    class LinterConfig
      # Valid severity levels
      SEVERITY_LEVELS = %i[error warn warning info hint off].freeze #: Array[Symbol]

      # Severity aliases mapping
      SEVERITY_ALIASES = { "warning" => :warn }.freeze #: Hash[String, Symbol]

      # @rbs @config: Hash[String, untyped]
      # @rbs @linter_config: Hash[String, untyped]

      # Initialize with merged configuration hash
      # @rbs config: Hash[String, untyped]
      def initialize(config) #: void
        @config = config
        @linter_config = config.fetch("linter", {})
      end

      # Check if linter is enabled
      def enabled? #: bool
        @linter_config.fetch("enabled", true)
      end

      # Get file patterns to include
      def include_patterns #: Array[String]
        @linter_config.fetch("include", Defaults::DEFAULT_INCLUDE.dup)
      end

      # Get file patterns to exclude
      def exclude_patterns #: Array[String]
        @linter_config.fetch("exclude", Defaults::DEFAULT_EXCLUDE.dup)
      end

      # Get all rule configurations
      def rules #: Hash[String, untyped]
        @linter_config.fetch("rules", {})
      end

      # Check if a rule is enabled
      # @rbs rule_name: String
      def rule_enabled?(rule_name) #: bool
        rule_config = rules[normalize_rule_name(rule_name)]
        return true if rule_config.nil?

        severity = extract_severity(rule_config)
        severity != :off
      end

      # Get the severity level for a rule
      # @rbs rule_name: String
      # @rbs default: Symbol -- default severity if rule is not configured
      def rule_severity(rule_name, default: :warn) #: Symbol
        rule_config = rules[normalize_rule_name(rule_name)]
        return default if rule_config.nil?

        extract_severity(rule_config)
      end

      # Get rule-specific options
      # @rbs rule_name: String
      def rule_options(rule_name) #: Hash[String, untyped]
        rule_config = rules[normalize_rule_name(rule_name)]
        extract_options(rule_config)
      end

      private

      # Normalize rule name to string with kebab-case
      # @rbs rule_name: String | Symbol
      def normalize_rule_name(rule_name) #: String
        rule_name.to_s.tr("_", "-")
      end

      # Extract severity from rule configuration
      # @rbs rule_config: String | Symbol | Hash[String | Symbol, untyped] | nil
      def extract_severity(rule_config) #: Symbol
        severity = case rule_config
                   when String, Symbol
                     rule_config.to_s
                   when Hash
                     fetch_from_hash(rule_config, "severity")&.to_s || "warn"
                   else
                     "warn"
                   end

        normalize_severity(severity)
      end

      # Extract options from rule configuration
      # @rbs rule_config: String | Symbol | Hash[String | Symbol, untyped] | nil
      def extract_options(rule_config) #: Hash[String, untyped]
        return {} unless rule_config.is_a?(Hash)

        result = fetch_from_hash(rule_config, "options")
        result.is_a?(Hash) ? result : {}
      end

      # Fetch value from hash supporting both string and symbol keys
      # @rbs hash: Hash[String | Symbol, untyped]
      # @rbs key: String
      def fetch_from_hash(hash, key) #: untyped
        hash[key] || hash[key.to_sym]
      end

      # Normalize severity string to symbol
      # @rbs severity: String
      def normalize_severity(severity) #: Symbol
        normalized = SEVERITY_ALIASES[severity] || severity.to_sym

        SEVERITY_LEVELS.include?(normalized) ? normalized : :warn
      end
    end
  end
end
