# frozen_string_literal: true

module Herb
  module Lint
    # Linter processes a single file and returns lint results.
    # It applies a set of rules to a parsed document and collects offenses.
    class Linter
      attr_reader :rules #: Array[Rules::Base | Rules::VisitorRule]
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :rule_registry #: RuleRegistry?
      attr_reader :ignore_disable_comments #: bool

      # @rbs rules: Array[Rules::Base | Rules::VisitorRule]
      # @rbs config: Herb::Config::LinterConfig
      # @rbs rule_registry: RuleRegistry? -- optional registry for severity lookup
      # @rbs ignore_disable_comments: bool -- when true, report offenses even when suppressed
      def initialize(rules, config, rule_registry: nil, ignore_disable_comments: false) #: void
        @rules = rules
        @config = config
        @rule_registry = rule_registry
        @ignore_disable_comments = ignore_disable_comments
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
        return LintResult.new(file_path:, offenses: [], source:, parse_result:) if directives.ignore_file?

        context = Context.new(file_path:, source:, config:, directives:, rule_registry:)
        offenses = collect_offenses(parse_result, context)
        build_lint_result(file_path, source, parse_result, directives, offenses)
      end

      private

      # @rbs parse_result: Herb::ParseResult
      # @rbs context: Context
      def collect_offenses(parse_result, context) #: Array[Offense]
        rules.flat_map { |rule| rule.check(parse_result, context) }
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
        return LintResult.new(file_path:, offenses:, source:, parse_result:) if ignore_disable_comments

        kept_offenses, ignored_offenses = directives.filter_offenses(offenses)
        unnecessary = UnnecessaryDirectiveDetector.detect(directives, ignored_offenses)
        LintResult.new(
          file_path:,
          offenses: kept_offenses + unnecessary,
          source:,
          ignored_count: ignored_offenses.size,
          parse_result:
        )
      end

      # @rbs file_path: String
      # @rbs source: String
      # @rbs errors: Array[untyped]
      def parse_error_result(file_path, source, errors) #: LintResult
        offenses = errors.map { |error| parse_error_offense(error) }
        LintResult.new(file_path:, offenses:, source:)
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
