# frozen_string_literal: true

module Herb
  module Lint
    # Represents a single linting violation.
    class Offense
      attr_reader :rule_name #: String
      attr_reader :message #: String
      attr_reader :severity #: String
      attr_reader :location #: Herb::Location

      # @rbs rule_name: String
      # @rbs message: String
      # @rbs severity: String
      # @rbs location: Herb::Location
      def initialize(rule_name:, message:, severity:, location:) #: void
        @rule_name = rule_name
        @message = message
        @severity = severity
        @location = location
      end

      # Returns the starting line number of the offense.
      def line #: Integer
        location.start.line
      end

      # Returns the starting column number of the offense.
      def column #: Integer
        location.start.column
      end
    end
  end
end
