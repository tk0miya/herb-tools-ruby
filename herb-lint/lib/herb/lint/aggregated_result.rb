# frozen_string_literal: true

module Herb
  module Lint
    # Aggregates linting results across multiple files.
    class AggregatedResult
      attr_reader :results #: Array[LintResult]
      attr_reader :rule_count #: Integer
      attr_reader :start_time #: Time?
      attr_reader :duration #: Integer?

      # @rbs results: Array[LintResult]
      # @rbs rule_count: Integer
      # @rbs start_time: Time? -- when linting started, or nil if not tracked
      # @rbs duration: Integer? -- elapsed time in milliseconds, or nil if not tracked
      def initialize(results, rule_count: 0, start_time: nil, duration: nil) #: void
        @results = results
        @rule_count = rule_count
        @start_time = start_time
        @duration = duration
      end

      # Returns the total number of offenses across all files.
      def offense_count #: Integer
        results.sum(&:offense_count)
      end

      # Returns the total number of errors across all files.
      def error_count #: Integer
        results.sum(&:error_count)
      end

      # Returns the total number of warnings across all files.
      def warning_count #: Integer
        results.sum(&:warning_count)
      end

      # Returns the total number of info-level offenses across all files.
      def info_count #: Integer
        results.sum(&:info_count)
      end

      # Returns the total number of hint-level offenses across all files.
      def hint_count #: Integer
        results.sum(&:hint_count)
      end

      # Returns the total number of ignored offenses across all files.
      def ignored_count #: Integer
        results.sum(&:ignored_count)
      end

      # Returns the number of files processed.
      def file_count #: Integer
        results.size
      end

      # Returns true if there are no offenses.
      def success? #: bool
        offense_count.zero?
      end

      # Returns all offenses across all files.
      def offenses #: Array[Offense]
        results.flat_map(&:unfixed_offenses)
      end

      # Returns all unfixed offenses across all files.
      def unfixed_offenses #: Array[Offense]
        results.flat_map(&:unfixed_offenses)
      end

      # Returns the total number of autofixed offenses across all files.
      def autofixed_count #: Integer
        results.sum(&:autofixed_count)
      end

      # Returns the total number of autofixable offenses across all files.
      def autofixable_count #: Integer
        results.sum(&:autofixable_count)
      end

      # Returns the number of files that have offenses.
      def files_with_offenses_count #: Integer
        @files_with_offenses_count ||= results.count { |r| r.offense_count.positive? }
      end
    end
  end
end
