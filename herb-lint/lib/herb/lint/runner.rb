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
      attr_reader :unsafe #: bool
      attr_reader :linter #: Linter

      # @rbs config: Herb::Config::LinterConfig
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      # @rbs fix: bool -- when true, apply safe automatic fixes
      # @rbs unsafe: bool -- when true, apply all fixes including unsafe ones
      def initialize(config, ignore_disable_comments: false, fix: false, unsafe: false) #: void
        @config = config
        @ignore_disable_comments = ignore_disable_comments
        @fix = fix
        @unsafe = unsafe
        @linter = build_linter
      end

      # Run linting on the given paths and return aggregated results.
      # @rbs paths: Array[String] -- explicit paths (files or directories) to lint
      def run(paths = []) #: AggregatedResult
        results = discover_files(paths).map { process_file(_1) }
        AggregatedResult.new(results)
      end

      # Process a single file: lint and optionally apply fixes.
      # @rbs file_path: String
      def process_file(file_path) #: LintResult
        source = File.read(file_path)
        result = linter.lint(file_path:, source:)

        return result unless fix

        auto_fixer = build_auto_fixer(result)
        return result unless auto_fixer.fixable?

        fix_result = auto_fixer.apply

        # Write fixed content back to file if it changed
        File.write(file_path, fix_result.source) if fix_result.source != source

        # Return updated LintResult with only unfixed offenses
        LintResult.new(
          file_path: result.file_path,
          offenses: fix_result.unfixed,
          source: fix_result.source,
          parse_result: result.parse_result
        )
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
        registry = RuleRegistry.new
        registry.load_builtin_rules
        rules = registry.all.map(&:new)

        Linter.new(rules, config, rule_registry: registry, ignore_disable_comments:)
      end

      # @rbs result: LintResult
      def build_auto_fixer(result) #: AutoFixer
        AutoFixer.new(
          result.parse_result,
          result.offenses,
          unsafe:
        )
      end
    end
  end
end
