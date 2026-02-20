# frozen_string_literal: true

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

        CONTEXT_LINES = 2 # Number of lines to show before and after the offense

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          super
          @summary_reporter = Herb::Lint::Reporter::SummaryReporter.new(io:)
        end

        # Reports the aggregated linting result.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          results_with_offenses = aggregated_result.results.select { |r| r.offense_count.positive? }

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
          # Print offense header
          print_offense_header(offense)

          # Print source code lines
          print_source_lines(offense, source_lines)
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

        # Prints source code lines around the offense.
        #
        # @rbs offense: Offense
        # @rbs source_lines: Array[String]
        def print_source_lines(offense, source_lines) #: void
          start_line = [1, offense.line - CONTEXT_LINES].max
          end_line = [source_lines.size, offense.line + CONTEXT_LINES].min

          max_line_num_width = end_line.to_s.size

          (start_line..end_line).each do |line_num|
            line_content = source_lines[line_num - 1]&.chomp || ""
            print_source_line(line_num, line_content, offense, max_line_num_width)
          end
        end

        # Prints a single source code line with line number and highlighting.
        #
        # @rbs line_num: Integer
        # @rbs content: String
        # @rbs offense: Offense
        # @rbs width: Integer
        def print_source_line(line_num, content, offense, width) #: void
          is_offense_line = (line_num == offense.line)

          # Format line number
          line_num_str = line_num.to_s.rjust(width)
          if is_offense_line
            line_num_display = colorize(line_num_str, color: :red, bold: true)
            separator = colorize(" | ", color: :red, bold: true)
          else
            line_num_display = colorize(line_num_str, color: :gray, dim: true)
            separator = colorize(" | ", color: :gray)
          end

          io.puts "  #{line_num_display}#{separator}#{content}"

          # Print column indicator for the offense line
          print_column_indicator(offense, width) if is_offense_line
        end

        # Prints the column indicator (caret) pointing to the offense location.
        #
        # @rbs offense: Offense
        # @rbs line_num_width: Integer
        def print_column_indicator(offense, line_num_width) #: void
          spacing = indicator_spacing(offense, line_num_width)
          caret = colorize("^" * indicator_caret_length(offense), color: :red, bold: true)
          io.puts "#{spacing}#{caret}"
        end

        # Calculates the spacing string before the caret.
        #
        # @rbs offense: Offense
        # @rbs line_num_width: Integer
        def indicator_spacing(offense, line_num_width) #: String
          # Use [col - 1, 0].max to handle column 0 (1-based columns minus 1 for offset)
          column_offset = [offense.column - 1, 0].max
          "  #{' ' * line_num_width} | #{' ' * column_offset}"
        end

        # Calculates the caret length based on the offense location range.
        #
        # @rbs offense: Offense
        def indicator_caret_length(offense) #: Integer
          if offense.location.end.line == offense.line
            # Multi-column offense on same line
            [offense.location.end.column - offense.column + 1, 1].max
          else
            # Multi-line offense or single character
            1
          end
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
