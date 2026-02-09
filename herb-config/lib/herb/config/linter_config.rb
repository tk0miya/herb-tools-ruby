# frozen_string_literal: true

require_relative "pattern_matcher"

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

      # Returns the names of rules that are explicitly disabled in configuration.
      # A rule is considered disabled if its "enabled" option is set to false.
      def disabled_rule_names #: Array[String]
        rules.select { |_name, opts| opts["enabled"] == false }.keys
      end

      # Returns the options for a specific rule.
      # Returns an empty hash if no options are configured.
      # @rbs rule_name: String -- the name of the rule
      def rule_options(rule_name) #: Hash[String, untyped]
        rules.dig(rule_name, "options") || {}
      end

      # Checks if a rule is enabled.
      # Rules are enabled by default unless explicitly disabled in config.
      # The default parameter allows specifying a different default for rules
      # that should be disabled by default.
      # @rbs rule_name: String -- the name of the rule
      # @rbs default: bool -- the default enabled state if not configured (default: true)
      def enabled_rule?(rule_name, default: true) #: bool
        value = rules.dig(rule_name, "enabled")
        value.nil? ? default : value
      end

      # Returns the fail level for the linter.
      # This determines which severity levels should cause non-zero exit codes.
      # Defaults to "error" if not configured.
      # @rbs return: String
      def fail_level #: String
        linter_config["failLevel"] || "error"
      end

      # Returns the include patterns for a specific rule.
      # These patterns are additive to the global include patterns.
      # @rbs rule_name: String -- the name of the rule
      # @rbs return: Array[String]
      def rule_include_patterns(rule_name) #: Array[String]
        rules.dig(rule_name, "include") || []
      end

      # Returns the only patterns for a specific rule.
      # When present, these patterns override all include patterns.
      # @rbs rule_name: String -- the name of the rule
      # @rbs return: Array[String]
      def rule_only_patterns(rule_name) #: Array[String]
        rules.dig(rule_name, "only") || []
      end

      # Returns the exclude patterns for a specific rule.
      # These patterns are additive to the global exclude patterns.
      # @rbs rule_name: String -- the name of the rule
      # @rbs return: Array[String]
      def rule_exclude_patterns(rule_name) #: Array[String]
        rules.dig(rule_name, "exclude") || []
      end

      # Build a pattern matcher for a specific rule.
      # @rbs base_dir: String
      # @rbs rule_name: String
      # @rbs return: PatternMatcher
      def build_pattern_matcher(base_dir, rule_name) #: PatternMatcher
        all_includes = include_patterns + rule_include_patterns(rule_name)
        all_excludes = exclude_patterns + rule_exclude_patterns(rule_name)
        only = rule_only_patterns(rule_name)

        PatternMatcher.new(
          base_dir:,
          include: all_includes,
          exclude: all_excludes,
          only:
        )
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
