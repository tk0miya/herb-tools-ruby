# frozen_string_literal: true

require "herb/core"

module Herb
  module Lint
    # Runner orchestrates the linting process for multiple files.
    # It handles file discovery, rule instantiation, and result aggregation.
    class Runner
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :ignore_disable_comments #: bool
      attr_reader :autofix #: bool
      attr_reader :unsafe #: bool
      attr_reader :linter #: Linter

      # @rbs config: Herb::Config::LinterConfig
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      # @rbs autofix: bool -- when true, apply safe automatic fixes
      # @rbs unsafe: bool -- when true, also apply unsafe fixes (requires autofix: true)
      # @rbs rule_registry: RuleRegistry? -- optional custom rule registry (for testing)
      def initialize(config, ignore_disable_comments: false, autofix: false, unsafe: false, rule_registry: nil) #: void
        @config = config
        @ignore_disable_comments = ignore_disable_comments
        @autofix = autofix
        @unsafe = unsafe
        @linter = build_linter(rule_registry)
      end

      # Run linting on the given paths and return aggregated results.
      # @rbs paths: Array[String] -- explicit paths (files or directories) to lint
      def run(paths = []) #: AggregatedResult
        files = discover_files(paths)
        results = files.map { process_file(_1) }
        AggregatedResult.new(results)
      end

      private

      # Process a single file: lint and optionally apply fixes.
      # @rbs file_path: String
      def process_file(file_path) #: LintResult
        source = File.read(file_path)
        result = linter.lint(file_path:, source:)
        autofixer = build_autofixer(result)

        if autofix && autofixer.autofixable?(unsafe:)
          autofix_result = autofixer.apply
          File.write(file_path, autofix_result.source) if autofix_result.source != source
          # Return LintResult with unfixed offenses and track autofixed offenses
          LintResult.new(
            file_path: result.file_path,
            unfixed_offenses: autofix_result.unfixed,
            source: autofix_result.source,
            parse_result: result.parse_result,
            autofixed_offenses: autofix_result.fixed
          )
        else
          result
        end
      end

      # @rbs paths: Array[String]
      def discover_files(paths) #: Array[String]
        discovery = Herb::Core::FileDiscovery.new(
          base_dir: Dir.pwd,
          include_patterns: config.include_patterns,
          exclude_patterns: config.exclude_patterns
        )
        discovery.discover(paths)
      end

      # Build and configure a Linter instance.
      # @rbs registry: RuleRegistry? -- optional custom rule registry (defaults to all built-in rules)
      def build_linter(registry = nil) #: Linter
        registry ||= RuleRegistry.new(config:)

        Linter.new(config, rule_registry: registry, ignore_disable_comments:)
      end

      # Build an Autofixer for the given lint result.
      # @rbs lint_result: LintResult
      def build_autofixer(lint_result) #: Autofixer
        Autofixer.new(
          lint_result.parse_result,
          lint_result.unfixed_offenses,
          unsafe:
        )
      end
    end
  end
end
