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

      # Returns the file patterns to include in linting.
      # Merges patterns from both the top-level 'files' section and 'linter' section.
      def include_patterns #: Array[String]
        files_config.fetch("include", []) + linter_config.fetch("include", [])
      end

      # Returns the file patterns to exclude from linting.
      # If linter.exclude is specified, it takes precedence (override behavior).
      # Otherwise, falls back to files.exclude.
      def exclude_patterns #: Array[String]
        linter_config["exclude"] || files_config["exclude"] || []
      end

      # Returns the rules configuration hash
      def rules #: Hash[String, Hash[String, untyped]]
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

      # Returns the names of rules that are explicitly disabled in configuration.
      # A rule is considered disabled if its "enabled" option is set to false.
      def disabled_rule_names #: Array[String]
        rules.select { |_name, opts| opts["enabled"] == false }.keys
      end

      # Returns the fail level for the linter.
      # This determines which severity levels should cause non-zero exit codes.
      # Defaults to "error" if not configured.
      # @rbs return: String
      def fail_level #: String
        linter_config["failLevel"] || "error"
      end

      private

      attr_reader :config #: Hash[String, untyped]

      def linter_config #: Hash[String, untyped]
        config["linter"] || {}
      end

      def files_config #: Hash[String, untyped]
        config["files"] || {}
      end
    end
  end
end
