# frozen_string_literal: true

module Herb
  module Lint
    # Represents a single linting violation.
    class Offense
      attr_reader :rule_name #: String
      attr_reader :message #: String
      attr_reader :severity #: String
      attr_reader :location #: Herb::Location
      attr_reader :autofix_context #: AutofixContext?

      # @rbs rule_name: String
      # @rbs message: String
      # @rbs severity: String
      # @rbs location: Herb::Location
      # @rbs autofix_context: AutofixContext? -- optional autofix context for fixable offenses
      def initialize(rule_name:, message:, severity:, location:, autofix_context: nil) #: void
        @rule_name = rule_name
        @message = message
        @severity = severity
        @location = location
        @autofix_context = autofix_context
      end

      # Returns true when the offense can be automatically fixed.
      def fixable? #: bool
        !@autofix_context.nil?
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
