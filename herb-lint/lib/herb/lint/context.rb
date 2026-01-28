# frozen_string_literal: true

module Herb
  module Lint
    # Linting context with file information.
    # Provides access to file path, source code, and configuration.
    class Context
      attr_reader :file_path #: String
      attr_reader :source #: String
      attr_reader :config #: Herb::Config::LinterConfig

      # @rbs file_path: String -- path to the file being linted
      # @rbs source: String -- source code content of the file
      # @rbs config: Herb::Config::LinterConfig -- linter configuration
      # @rbs rule_registry: RuleRegistry? -- optional registry to look up rule defaults
      def initialize(file_path:, source:, config:, rule_registry: nil) #: void
        @file_path = file_path
        @source = source
        @config = config
        @rule_registry = rule_registry
      end

      # Returns the severity for a specific rule.
      # Checks configuration first, falls back to rule's default severity,
      # then defaults to "error".
      # @rbs rule_name: String -- the name of the rule
      def severity_for(rule_name) #: String
        config.rule_severity(rule_name) ||
          @rule_registry&.get(rule_name)&.default_severity ||
          "error"
      end
    end
  end
end
