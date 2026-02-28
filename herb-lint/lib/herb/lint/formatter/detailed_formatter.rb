# frozen_string_literal: true

require "herb/highlight"

require_relative "base"
require_relative "../console_utils"
require_relative "../string_utils"
require_relative "../reporter/summary_reporter"

module Herb
  module Lint
    module Formatter
      # Detailed formatter that outputs linting results with source code context.
      #
      # This formatter displays offenses for each file with severity symbols, colors,
      # and surrounding source code lines for better context.
      class DetailedFormatter < Base
        include ConsoleUtils
        include StringUtils

        # @rbs @summary_reporter: Herb::Lint::Reporter::SummaryReporter
        # @rbs @diagnostic_renderer: Herb::Highlight::DiagnosticRenderer

        # @rbs io: IO
        # @rbs show_timing: bool -- when false, suppresses timing display
        def initialize(io: $stdout, show_timing: true) #: void
          super(io:)
          @summary_reporter = Herb::Lint::Reporter::SummaryReporter.new(io:, show_timing:)
          @diagnostic_renderer = Herb::Highlight::DiagnosticRenderer.new(tty: io.tty?)
        end

        # Reports the aggregated linting result.
        # Outputs the disabled message when aggregated_result.completed? is false.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          return io.puts(aggregated_result.message) unless aggregated_result.completed?

          results_with_offenses = aggregated_result.results.select { _1.offense_count.positive? }

          results_with_offenses.each_with_index do |result, index|
            print_file_header(result, index + 1, results_with_offenses.size)
            print_offenses(result)
            io.puts unless index == results_with_offenses.size - 1
          end

          @summary_reporter.display_summary(aggregated_result)
        end

        private

        # Prints the file header with progress indicator for multiple files.
        #
        # @rbs result: LintResult
        # @rbs current: Integer
        # @rbs total: Integer
        def print_file_header(result, current, total) #: void
          if total > 1
            progress = colorize("[#{current}/#{total}]", color: :gray, dim: true)
            separator = colorize("─" * 50, color: :gray)
            io.puts "#{separator} #{progress}"
          end

          io.puts result.file_path
          io.puts
        end

        # Prints offenses with surrounding source code.
        #
        # @rbs result: LintResult
        def print_offenses(result) #: void
          source_lines = result.source.lines

          result.unfixed_offenses.each do |offense|
            print_offense(offense, source_lines)
            io.puts
          end
        end

        # Prints a single offense with source code.
        #
        # @rbs offense: Offense
        # @rbs source_lines: Array[String]
        def print_offense(offense, source_lines) #: void
          print_offense_header(offense)
          io.print @diagnostic_renderer.render(
            source_lines,
            line: offense.line,
            column: offense.column,
            severity: offense.severity,
            end_line: offense.location.end.line,
            end_column: offense.location.end.column
          )
        end

        # Prints the offense header line.
        #
        # @rbs offense: Offense
        def print_offense_header(offense) #: void
          location = format("%<line>d:%<column>d", line: offense.line, column: offense.column)
          symbol = severity_symbol(offense.severity)
          rule_code = colorize("(#{offense.rule_name})", color: :cyan)

          line = "  #{location.ljust(6)} #{symbol} #{offense.message} #{rule_code}"

          # Append [Correctable] label for autofixable offenses
          line += " #{colorize('[Correctable]', color: :green, bold: true)}" if offense.autofixable?

          io.puts line
          io.puts
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
