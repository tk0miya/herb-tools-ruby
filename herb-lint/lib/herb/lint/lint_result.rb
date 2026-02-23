# frozen_string_literal: true

module Herb
  module Lint
    # Represents the linting result for a single file.
    class LintResult
      attr_reader :file_path #: String
      attr_reader :unfixed_offenses #: Array[Offense]
      attr_reader :source #: String
      attr_reader :ignored_count #: Integer
      attr_reader :parse_result #: Herb::ParseResult?
      attr_reader :autofixed_offenses #: Array[Offense]

      # @rbs file_path: String
      # @rbs unfixed_offenses: Array[Offense] -- offenses that were not fixed
      # @rbs source: String
      # @rbs ignored_count: Integer -- number of offenses suppressed by directives
      # @rbs parse_result: Herb::ParseResult? -- parsed AST for autofix phase (nil on parse error)
      # @rbs autofixed_offenses: Array[Offense] -- offenses that were automatically fixed
      def initialize( # rubocop:disable Metrics/ParameterLists
        file_path:,
        unfixed_offenses:,
        source:,
        ignored_count: 0,
        parse_result: nil,
        autofixed_offenses: []
      ) #: void
        @file_path = file_path
        @unfixed_offenses = unfixed_offenses
        @source = source
        @ignored_count = ignored_count
        @parse_result = parse_result
        @autofixed_offenses = autofixed_offenses
      end

      # Returns the count of errors.
      def error_count #: Integer
        unfixed_offenses.count { _1.severity == "error" }
      end

      # Returns the count of warnings.
      def warning_count #: Integer
        unfixed_offenses.count { _1.severity == "warning" }
      end

      # Returns the count of info-level offenses.
      def info_count #: Integer
        unfixed_offenses.count { _1.severity == "info" }
      end

      # Returns the count of hint-level offenses.
      def hint_count #: Integer
        unfixed_offenses.count { _1.severity == "hint" }
      end

      # Returns the total number of offenses.
      def offense_count #: Integer
        unfixed_offenses.size
      end

      # Returns the number of offenses that were automatically fixed.
      def autofixed_count #: Integer
        autofixed_offenses.size
      end

      # Returns the number of autofixable offenses (offenses that can be fixed).
      # Counts all offenses with autofix context, regardless of safety level.
      def autofixable_count #: Integer
        unfixed_offenses.count { _1.autofixable?(unsafe: true) }
      end
    end
  end
end
