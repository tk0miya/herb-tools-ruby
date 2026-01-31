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
      # 4. Create Context and execute each enabled rule against the AST
      # 5. Filter offenses using directives (unless ignore_disable_comments)
      # 6. Return LintResult with kept offenses and ignored count
      #
      # @rbs file_path: String -- path to the file being linted
      # @rbs source: String -- source code content of the file
      def lint(file_path:, source:) #: LintResult
        document = Herb.parse(source)
        return parse_error_result(file_path, source, document.errors) if document.failed?

        directives = DirectiveParser.parse(document, source)
        return LintResult.new(file_path:, offenses: [], source:) if directives.ignore_file?

        context = build_context(file_path, source)
        all_offenses = collect_offenses(document, context)

        if ignore_disable_comments
          LintResult.new(file_path:, offenses: all_offenses, source:)
        else
          kept_offenses, ignored_offenses = directives.filter_offenses(all_offenses)
          LintResult.new(file_path:, offenses: kept_offenses, source:, ignored_count: ignored_offenses.size)
        end
      end

      private

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
