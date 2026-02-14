# frozen_string_literal: true

require_relative "base"
require_relative "../console_utils"
require_relative "../string_utils"
require_relative "../reporter/summary_reporter"

module Herb
  module Lint
    module Formatter
      # Simple formatter that outputs linting results in a human-readable format.
      #
      # This formatter displays offenses for each file with severity symbols and colors.
      class SimpleFormatter < Base
        include ConsoleUtils
        include StringUtils

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          super
          @summary_reporter = Herb::Lint::Reporter::SummaryReporter.new(io:)
        end

        # Reports the aggregated linting result.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          aggregated_result.results.each do |result|
            print_offenses(result) if result.offense_count.positive?
          end

          @summary_reporter.display_summary(aggregated_result)
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

        # Returns the colored symbol for a severity level.
        #
        # @rbs severity: String
        def severity_symbol(severity) #: String
          case severity
          when "error"
            colorize("✗", color: :red, bold: true)
          when "warning"
            colorize("⚠", color: :yellow, bold: true)
          else
            colorize("ℹ", color: :cyan)
          end
        end

        # Wraps ConsoleUtils#colorize to automatically use io.tty?
        #
        # @rbs text: String
        # @rbs color: color?
        # @rbs bold: bool
        # @rbs dim: bool
        def colorize(text, color: nil, bold: false, dim: false) #: String
          super(text, color:, bold:, dim:, tty: io.tty?)
        end
      end
    end
  end
end
