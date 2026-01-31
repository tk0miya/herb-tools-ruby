# frozen_string_literal: true

module Herb
  module Lint
    # Represents a single linting violation.
    class Offense
      attr_reader :rule_name #: String
      attr_reader :message #: String
      attr_reader :severity #: String
      attr_reader :location #: Herb::Location
      attr_reader :fix #: Proc?
      attr_reader :unsafe #: bool

      # @rbs rule_name: String
      # @rbs message: String
      # @rbs severity: String
      # @rbs location: Herb::Location
      # @rbs fix: Proc? -- proc that takes source string and returns fixed source
      # @rbs unsafe: bool -- whether the fix is potentially unsafe
      def initialize(rule_name:, message:, severity:, location:, fix: nil, unsafe: false) #: void # rubocop:disable Metrics/ParameterLists
        @rule_name = rule_name
        @message = message
        @severity = severity
        @location = location
        @fix = fix
        @unsafe = unsafe
      end

      # Returns whether this offense has an auto-fix available.
      def fixable? #: bool
        !fix.nil?
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
