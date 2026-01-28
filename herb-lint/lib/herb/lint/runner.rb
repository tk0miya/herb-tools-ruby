# frozen_string_literal: true

require "herb/core"

module Herb
  module Lint
    # Runner orchestrates the linting process for multiple files.
    # It handles file discovery, rule instantiation, and result aggregation.
    class Runner
      attr_reader :config #: Herb::Config::LinterConfig

      # @rbs config: Herb::Config::LinterConfig
      def initialize(config) #: void
        @config = config
      end

      # Run linting on the given paths and return aggregated results.
      # @rbs paths: Array[String] -- explicit paths (files or directories) to lint
      def run(paths = []) #: AggregatedResult
        files = discover_files(paths)
        rules = instantiate_rules
        linter = Linter.new(rules, config, rule_registry:)

        results = files.map do |file_path|
          source = File.read(file_path)
          linter.lint(file_path:, source:)
        end

        AggregatedResult.new(results)
      end

      private

      # @rbs paths: Array[String]
      def discover_files(paths) #: Array[String]
        discovery = Herb::Core::FileDiscovery.new(
          base_dir: Dir.pwd,
          include_patterns: config.include_patterns,
          exclude_patterns: config.exclude_patterns
        )
        discovery.discover(paths)
      end

      def rule_registry #: RuleRegistry
        @rule_registry ||= build_rule_registry
      end

      def build_rule_registry #: RuleRegistry
        registry = RuleRegistry.new
        registry.load_builtin_rules
        registry
      end

      def instantiate_rules #: Array[Rules::Base | Rules::VisitorRule]
        rule_registry.all.map(&:new)
      end
    end
  end
end
