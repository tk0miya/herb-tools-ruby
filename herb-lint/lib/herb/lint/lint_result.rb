# frozen_string_literal: true

module Herb
  module Lint
    # Represents the linting result for a single file.
    class LintResult
      attr_reader :file_path #: String
      attr_reader :offenses #: Array[Offense]
      attr_reader :source #: String
      attr_reader :ignored_count #: Integer

      # @rbs file_path: String
      # @rbs offenses: Array[Offense]
      # @rbs source: String
      # @rbs ignored_count: Integer -- number of offenses suppressed by directives
      def initialize(file_path:, offenses:, source:, ignored_count: 0) #: void
        @file_path = file_path
        @offenses = offenses
        @source = source
        @ignored_count = ignored_count
      end

      # Returns the count of errors.
      def error_count #: Integer
        offenses.count { |offense| offense.severity == "error" }
      end

      # Returns the count of warnings.
      def warning_count #: Integer
        offenses.count { |offense| offense.severity == "warning" }
      end

      # Returns the total number of offenses.
      def offense_count #: Integer
        offenses.size
      end
    end
  end
end
