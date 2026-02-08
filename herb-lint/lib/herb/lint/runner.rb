# frozen_string_literal: true

require "herb/core"

module Herb
  module Lint
    # Runner orchestrates the linting process for multiple files.
    # It handles file discovery, rule instantiation, and result aggregation.
    class Runner
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :ignore_disable_comments #: bool
      attr_reader :fix #: bool
      attr_reader :fix_unsafely #: bool
      attr_reader :linter #: Linter

      # @rbs config: Herb::Config::LinterConfig
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      # @rbs fix: bool -- when true, apply safe automatic fixes
      # @rbs fix_unsafely: bool -- when true, apply all fixes including unsafe ones
      def initialize(config, ignore_disable_comments: false, fix: false, fix_unsafely: false) #: void
        @config = config
        @ignore_disable_comments = ignore_disable_comments
        @fix = fix
        @fix_unsafely = fix_unsafely
        @linter = build_linter
      end

      # Run linting on the given paths and return aggregated results.
      # @rbs paths: Array[String] -- explicit paths (files or directories) to lint
      def run(paths = []) #: AggregatedResult
        files = discover_files(paths)
        results = files.map { |file_path| process_file(file_path) }
        AggregatedResult.new(results)
      end

      # Process a single file: lint and optionally apply fixes.
      # @rbs file_path: String
      def process_file(file_path) #: LintResult
        source = File.read(file_path)
        result = linter.lint(file_path:, source:)

        if fix && result.parse_result && result.offenses.any?(&:fixable?)
          fix_result = apply_fixes(result)

          # Write fixed content back to file if it changed
          File.write(file_path, fix_result.source) if fix_result.source != source

          # Return updated LintResult with only unfixed offenses
          LintResult.new(
            file_path: result.file_path,
            offenses: fix_result.unfixed,
            source: fix_result.source,
            parse_result: result.parse_result
          )
        else
          result
        end
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

      def build_linter #: Linter
        Linter.new(instantiate_rules, config, rule_registry:, ignore_disable_comments:)
      end

      # @rbs result: LintResult
      def apply_fixes(result) #: AutoFixResult
        AutoFixer.new(
          result.parse_result,
          result.offenses,
          unsafe: fix_unsafely
        ).apply
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
