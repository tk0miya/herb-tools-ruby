# frozen_string_literal: true

require "herb/core"

module Herb
  module Lint
    # Runner orchestrates the linting process for multiple files.
    # It handles file discovery, rule instantiation, and result aggregation.
    class Runner
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :ignore_disable_comments #: bool
      attr_reader :linter #: Linter

      # @rbs config: Herb::Config::LinterConfig
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      def initialize(config, ignore_disable_comments: false) #: void
        @config = config
        @ignore_disable_comments = ignore_disable_comments
        @linter = build_linter
      end

      # Run linting on the given paths and return aggregated results.
      # @rbs paths: Array[String] -- explicit paths (files or directories) to lint
      def run(paths = []) #: AggregatedResult
        files = discover_files(paths)

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

      # Build and configure a Linter instance with all rules loaded.
      # This consolidates rule registry creation, rule instantiation, and linter setup.
      def build_linter #: Linter
        registry = RuleRegistry.new
        registry.load_builtin_rules

        rules = registry.all.map(&:new)

        Linter.new(rules, config, rule_registry: registry, ignore_disable_comments:)
      end
    end
  end
end
