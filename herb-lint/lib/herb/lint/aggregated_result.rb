# frozen_string_literal: true

module Herb
  module Lint
    # Aggregates linting results across multiple files.
    class AggregatedResult
      attr_reader :results #: Array[LintResult]

      # @rbs results: Array[LintResult]
      def initialize(results) #: void
        @results = results
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
    end
  end
end
