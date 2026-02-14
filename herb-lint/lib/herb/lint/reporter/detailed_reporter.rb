# frozen_string_literal: true

require_relative "console_base"

module Herb
  module Lint
    module Reporter
      # Detailed reporter that outputs linting results with code context and syntax highlighting.
      class DetailedReporter < ConsoleBase
        attr_reader :context_lines #: Integer

        # @rbs io: IO
        # @rbs context_lines: Integer -- number of lines to show before/after offense
        # @rbs show_progress: bool -- whether to show progress counters
        def initialize(io: $stdout, context_lines: 2, show_progress: true) #: void
          super(io:, show_progress:)
          @context_lines = context_lines
          @current_offense_number = 1
          @total_offenses = 0
        end

        # Reports the aggregated linting result with detailed context.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          results_with_offenses = aggregated_result.results.select { _1.offense_count.positive? }

          # Calculate total offenses and reset counter
          @total_offenses = results_with_offenses.sum(&:offense_count)
          @current_offense_number = 1

          if results_with_offenses.size == 1
            print_file_offenses_single(results_with_offenses.first)
          else
            results_with_offenses.each_with_index do |result, index|
              print_file_offenses(result, index + 1, results_with_offenses.size)
            end
          end

          print_summary(aggregated_result)
        end

        private

        # Prints offenses for a single file (multi-file mode).
        #
        # @rbs result: LintResult
        # @rbs current: Integer
        # @rbs total: Integer
        def print_file_offenses(result, current, total) #: void
          result.unfixed_offenses.each_with_index do |offense, index|
            offense_number = @current_offense_number
            @current_offense_number += 1
            print_offense_detailed(offense, result.file_path, current, total, offense_number, @total_offenses)
            print_separator unless index == result.unfixed_offenses.size - 1
          end
          # Add separator between files
          print_separator unless current == total
        end

        # Prints offenses for a single file (single-file mode).
        #
        # @rbs result: LintResult
        def print_file_offenses_single(result) #: void
          io.puts colorize(result.file_path, color: :cyan, bold: true)
          io.puts

          result.unfixed_offenses.each_with_index do |offense, index|
            print_offense_with_context(offense, result.file_path)
            print_separator unless index == result.unfixed_offenses.size - 1
          end
        end

        # Prints file header with progress indicators.
        #
        # @rbs file_path: String
        # @rbs current_file: Integer
        # @rbs total_files: Integer
        # @rbs current_offense: Integer
        # @rbs total_offenses: Integer
        def print_file_header(file_path, current_file, total_files, current_offense, total_offenses) #: void
          header = colorize(file_path, color: :cyan, bold: true)
          if show_progress
            progress = colorize("[#{current_file}/#{total_files}]", color: :gray, dim: true)
            offense_progress = colorize("(#{current_offense}/#{total_offenses})", color: :gray, dim: true)
            header += " #{progress} #{offense_progress}"
          end
          io.puts header
          io.puts
        end

        # Prints a detailed offense with code context and progress.
        #
        # @rbs offense: Offense
        # @rbs file_path: String
        # @rbs current_file: Integer
        # @rbs total_files: Integer
        # @rbs current_offense: Integer
        # @rbs total_offenses: Integer
        # rubocop:disable Layout/LineLength, Metrics/ParameterLists
        def print_offense_detailed(offense, file_path, current_file, total_files, current_offense, total_offenses) #: void
          # rubocop:enable Layout/LineLength, Metrics/ParameterLists
          print_file_header(file_path, current_file, total_files, current_offense, total_offenses)
          print_offense_with_context(offense, file_path)
        end

        # Prints a single offense with surrounding code context.
        #
        # @rbs offense: Offense
        # @rbs file_path: String
        def print_offense_with_context(offense, file_path) #: void
          # Print offense details
          location = "#{offense.line}:#{offense.column}"
          symbol = severity_symbol(offense.severity)
          message = "#{symbol} #{offense.message}"
          rule = colorize("(#{offense.rule_name})", color: :cyan)

          io.puts "  #{colorize(location, color: :gray)} #{message} #{rule}"

          # Add [Correctable] label
          io.puts "  #{colorize('[Correctable]', color: :green, bold: true)}" if offense.autofixable?

          io.puts

          # Print code context
          print_code_context(file_path, offense)

          io.puts
        end

        # Prints the code context around an offense.
        #
        # @rbs file_path: String
        # @rbs offense: Offense
        def print_code_context(file_path, offense) #: void # rubocop:disable Metrics/AbcSize
          return unless File.exist?(file_path)

          lines = File.readlines(file_path, chomp: true)
          start_line = [offense.line - context_lines, 1].max
          end_line = [offense.line + context_lines, lines.size].min

          max_line_num_width = end_line.to_s.size

          (start_line..end_line).each do |line_num|
            line_content = lines[line_num - 1] || ""
            is_offense_line = line_num == offense.line

            print_code_line(line_num, line_content, is_offense_line, max_line_num_width, offense.column)
          end
        end

        # Prints a single line of code with line number and optional marker.
        #
        # @rbs line_num: Integer
        # @rbs line_content: String
        # @rbs is_offense_line: bool
        # @rbs width: Integer
        # @rbs column: Integer
        def print_code_line(line_num, line_content, is_offense_line, width, column) #: void
          line_num_str = line_num.to_s.rjust(width)
          gutter = " "

          if is_offense_line
            # Highlight the offense line
            line_num_colored = colorize(line_num_str, color: :red, bold: true)
            gutter_colored = colorize(">", color: :red, bold: true)
            io.puts "  #{line_num_colored} #{gutter_colored} #{line_content}"

            # Print column marker (caret pointing to the offense position)
            print_column_marker(width, column)
          else
            # Normal context line
            line_num_colored = colorize(line_num_str, color: :gray, dim: true)
            gutter_colored = colorize(gutter, color: :gray)
            io.puts "  #{line_num_colored} #{gutter_colored} #{colorize(line_content, color: :gray, dim: true)}"
          end
        end

        # Prints a caret marker pointing to the offense column.
        #
        # @rbs line_num_width: Integer
        # @rbs column: Integer
        def print_column_marker(line_num_width, column) #: void
          # Calculate spaces needed: line number width + gutter (2 chars) + column position
          spaces = " " * (line_num_width + 3 + column - 1)
          caret = colorize("^", color: :red, bold: true)
          io.puts "  #{spaces}#{caret}"
        end
      end
    end
  end
end
