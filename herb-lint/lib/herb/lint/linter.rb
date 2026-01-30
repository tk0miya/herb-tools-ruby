# frozen_string_literal: true

module Herb
  module Lint
    # Linter processes a single file and returns lint results.
    # It applies a set of rules to a parsed document, collects offenses,
    # and delegates directive-based filtering to DisableDirectives.
    class Linter
      attr_reader :rules #: Array[Rules::Base | Rules::VisitorRule]
      attr_reader :config #: Herb::Config::LinterConfig
      attr_reader :rule_registry #: RuleRegistry?

      # @rbs rules: Array[Rules::Base | Rules::VisitorRule]
      # @rbs config: Herb::Config::LinterConfig
      # @rbs rule_registry: RuleRegistry? -- optional registry for severity lookup
      def initialize(rules, config, rule_registry: nil) #: void
        @rules = rules
        @config = config
        @rule_registry = rule_registry
      end

      # Lint a single file and return the result.
      # @rbs file_path: String -- path to the file being linted
      # @rbs source: String -- source code content of the file
      def lint(file_path:, source:) #: LintResult
        directives = DisableCommentParser.parse(source)
        return ignored_result(file_path, source) if directives.ignore_file?

        document = Herb.parse(source)
        return parse_error_result(file_path, source, document.errors) if document.failed?

        offenses = collect_offenses(document, build_context(file_path, source))
        filtered = offenses.reject { |o| directives.rule_disabled?(o.line, o.rule_name) }
        LintResult.new(file_path:, offenses: filtered, source:)
      end

      private

      # @rbs file_path: String
      # @rbs source: String
      def ignored_result(file_path, source) #: LintResult
        LintResult.new(file_path:, offenses: [], source:, ignored: true)
      end

      # @rbs file_path: String
      # @rbs source: String
      def build_context(file_path, source) #: Context
        Context.new(file_path:, source:, config:, rule_registry:)
      end

      # @rbs document: Herb::ParseResult
      # @rbs context: Context
      def collect_offenses(document, context) #: Array[Offense]
        rules.flat_map { |rule| rule.check(document, context) }
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
          rule_name: "parse-error",
          message: error.message,
          severity: "error",
          location: error.location
        )
      end
    end
  end
end
