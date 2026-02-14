# frozen_string_literal: true

require_relative "console_base"

module Herb
  module Lint
    module Reporter
      # Simple reporter that outputs linting results in a human-readable format.
      class SimpleReporter < ConsoleBase
        # @rbs io: IO
        def initialize(io: $stdout) #: void
          super(io:, show_progress: false)
        end

        # Reports the aggregated linting result.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          aggregated_result.results.each do |result|
            print_offenses(result) if result.offense_count.positive?
          end

          print_summary(aggregated_result)
        end

        private

        # Prints offenses for a single file.
        #
        # @rbs result: LintResult
        def print_offenses(result) #: void
          io.puts result.file_path
          result.unfixed_offenses.each { print_offense(_1) }
          io.puts
        end

        # Prints a single offense.
        #
        # @rbs offense: Offense
        def print_offense(offense) #: void
          # Format: "  1:5   ✗ Message (rule-name) [Correctable]"
          location = format("%<line>d:%<column>d", line: offense.line, column: offense.column)
          symbol = severity_symbol(offense.severity)
          rule_code = colorize("(#{offense.rule_name})", color: :cyan)

          line = "  #{location.ljust(6)} #{symbol} #{offense.message} #{rule_code}"

          # Append [Correctable] label for autofixable offenses
          line += " #{colorize('[Correctable]', color: :green, bold: true)}" if offense.autofixable?

          io.puts line
        end
      end
    end
  end
end
