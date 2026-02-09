# frozen_string_literal: true

module Herb
  module Lint
    # Linter processes a single file and returns lint results.
    # It applies a set of rules to a parsed document and collects offenses.
    class Linter
      attr_reader :rules #: Array[Rules::Base | Rules::VisitorRule]
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :rule_registry #: RuleRegistry
      attr_reader :ignore_disable_comments #: bool

      # @rbs config: Herb::Config::LinterConfig
      # @rbs rule_registry: RuleRegistry -- registry for rule lookup and instantiation
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      def initialize(config, rule_registry:, ignore_disable_comments: false) #: void
        @config = config
        @rule_registry = rule_registry
        @ignore_disable_comments = ignore_disable_comments
        @rules = rule_registry.build_all(config:)
      end

      # Lint a single file and return the result.
      #
      # Processing flow:
      # 1. Parse ERB template into AST
      # 2. Parse directives via DirectiveParser
      # 3. Check for file-level ignore
      # 4. Create Context and execute rules against the AST
      # 5. Build LintResult (filtering offenses and detecting unnecessary directives)
      #
      # @rbs file_path: String -- path to the file being linted
      # @rbs source: String -- source code content of the file
      def lint(file_path:, source:) #: LintResult
        parse_result = Herb.parse(source, track_whitespace: true)
        return parse_error_result(file_path, source, parse_result.errors) if parse_result.failed?

        directives = DirectiveParser.parse(parse_result, source)
        return LintResult.new(file_path:, unfixed_offenses: [], source:, parse_result:) if directives.ignore_file?

        context = Context.new(file_path:, source:, config:, directives:, rule_registry:)
        offenses = collect_offenses(parse_result, context)
        build_lint_result(file_path, source, parse_result, directives, offenses)
      end

      private

      # @rbs parse_result: Herb::ParseResult
      # @rbs context: Context
      def collect_offenses(parse_result, context) #: Array[Offense]
        rules.flat_map do |rule|
          should_apply_rule?(rule.class.rule_name, context.file_path) ? rule.check(parse_result, context) : []
        end
      end

      # Determines if a rule should be applied to the given file path
      # based on per-rule include/only/exclude patterns.
      #
      # Pattern Resolution Logic:
      # 1. If rule has 'only': file must match one of 'only' patterns
      # 2. Else: file must match (linter.include OR rule.include)
      # 3. AND: file must NOT match (linter.exclude OR rule.exclude)
      #
      # @rbs rule_name: String
      # @rbs file_path: String
      def should_apply_rule?(rule_name, file_path) #: bool
        return false unless passes_only_check?(rule_name, file_path)
        return false unless passes_include_check?(rule_name, file_path)
        return false if matches_exclude_patterns?(rule_name, file_path)

        true
      end

      # Check if file passes 'only' pattern restrictions
      # @rbs rule_name: String
      # @rbs file_path: String
      def passes_only_check?(rule_name, file_path) #: bool
        only_patterns = config.rule_only_patterns(rule_name)
        return true if only_patterns.empty?

        matches_pattern?(only_patterns, file_path)
      end

      # Check if file passes include pattern requirements
      # @rbs rule_name: String
      # @rbs file_path: String
      def passes_include_check?(rule_name, file_path) #: bool
        only_patterns = config.rule_only_patterns(rule_name)
        return true if only_patterns.any? # Skip include check if 'only' is used

        all_includes = config.include_patterns + config.rule_include_patterns(rule_name)
        return true if all_includes.empty?

        matches_pattern?(all_includes, file_path)
      end

      # Check if file matches any exclude patterns
      # @rbs rule_name: String
      # @rbs file_path: String
      def matches_exclude_patterns?(rule_name, file_path) #: bool
        all_excludes = config.exclude_patterns + config.rule_exclude_patterns(rule_name)
        matches_pattern?(all_excludes, file_path)
      end

      # Check if file matches any pattern in the list
      # @rbs patterns: Array[String]
      # @rbs file_path: String
      def matches_pattern?(patterns, file_path) #: bool
        patterns.any? { |pattern| File.fnmatch?(pattern, file_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end

      # Build LintResult from offenses.
      # When ignore_disable_comments is false, filters offenses using directives
      # and detects unnecessary herb:disable directives.
      #
      # @rbs file_path: String
      # @rbs source: String
      # @rbs parse_result: Herb::ParseResult
      # @rbs directives: DirectiveParser::Directives
      # @rbs offenses: Array[Offense]
      def build_lint_result(file_path, source, parse_result, directives, offenses) #: LintResult
        return LintResult.new(file_path:, unfixed_offenses: offenses, source:, parse_result:) if ignore_disable_comments

        kept_offenses, ignored_offenses = directives.filter_offenses(offenses)
        unnecessary = UnnecessaryDirectiveDetector.detect(directives, ignored_offenses)
        LintResult.new(
          file_path:,
          unfixed_offenses: kept_offenses + unnecessary,
          source:,
          ignored_count: ignored_offenses.size,
          parse_result:
        )
      end

      # @rbs file_path: String
      # @rbs source: String
      # @rbs errors: Array[untyped]
      def parse_error_result(file_path, source, errors) #: LintResult
        unfixed_offenses = errors.map { parse_error_offense(_1) }
        LintResult.new(file_path:, unfixed_offenses:, source:)
      end

      # @rbs error: untyped
      def parse_error_offense(error) #: Offense
        Offense.new(
          rule_name: Rules::Parser::NoErrors.rule_name,
          message: error.message,
          severity: Rules::Parser::NoErrors.default_severity,
          location: error.location
        )
      end
    end
  end
end
