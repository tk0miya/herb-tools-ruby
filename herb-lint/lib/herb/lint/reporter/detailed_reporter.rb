# frozen_string_literal: true

require_relative "../string_utils"

module Herb
  module Lint
    module Reporter
      # Detailed reporter that outputs linting results with code context and syntax highlighting.
      class DetailedReporter # rubocop:disable Metrics/ClassLength
        include StringUtils

        attr_reader :io #: IO
        attr_reader :context_lines #: Integer
        attr_reader :show_progress #: bool

        # @rbs io: IO
        # @rbs context_lines: Integer -- number of lines to show before/after offense
        # @rbs show_progress: bool -- whether to show progress counters
        def initialize(io: $stdout, context_lines: 2, show_progress: true) #: void
          @io = io
          @context_lines = context_lines
          @show_progress = show_progress
        end

        # Reports the aggregated linting result with detailed context.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          results_with_offenses = aggregated_result.results.select { _1.offense_count.positive? }

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
            print_offense_detailed(offense, result.file_path, current, total, index + 1, result.unfixed_offenses.size)
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
          # Print header with file and progress
          header = colorize(file_path, color: :cyan, bold: true)
          if show_progress
            progress = colorize("[#{current_file}/#{total_files}]", color: :gray, dim: true)
            offense_progress = colorize("(#{current_offense}/#{total_offenses})", color: :gray, dim: true)
            header += " #{progress} #{offense_progress}"
          end
          io.puts header
          io.puts

          # Print offense with context
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

        # Prints a separator line between offenses.
        def print_separator #: void
          separator = colorize("─" * 80, color: :gray, dim: true)
          io.puts "  #{separator}"
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

        # Prints the summary of all offenses.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_summary(aggregated_result) #: void
          io.puts "\n"
          io.puts colorize(" Summary:", bold: true)

          print_checked_line(aggregated_result)
          print_files_line(aggregated_result) if aggregated_result.file_count > 1
          print_offenses_line(aggregated_result)
          print_fixable_line(aggregated_result)
          print_success_message(aggregated_result)
        end

        # Prints the "Checked" line showing total files processed.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_checked_line(aggregated_result) #: void
          file_count = aggregated_result.file_count
          file_word = pluralize(file_count, "file")
          io.puts " #{pad_label('Checked')} #{colorize("#{file_count} #{file_word}", color: :cyan)}"
        end

        # Prints the "Files" line showing clean vs files with offenses.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_files_line(aggregated_result) #: void
          total_files = aggregated_result.file_count
          files_with_offenses = aggregated_result.files_with_offenses_count
          clean_files = total_files - files_with_offenses

          if files_with_offenses.positive?
            with_offenses = colorize("#{files_with_offenses} with offenses", color: :red, bold: true)
            clean = colorize("#{clean_files} clean", color: :green, bold: true)
            total = colorize("(#{total_files} total)", color: :gray, dim: true)
            io.puts " #{pad_label('Files')} #{with_offenses} | #{clean} #{total}"
          else
            clean = colorize("#{total_files} clean", color: :green, bold: true)
            total = colorize("(#{total_files} total)", color: :gray, dim: true)
            line = " #{pad_label('Files')} #{clean} #{total}"
            io.puts colorize(line, dim: true)
          end
        end

        # Prints the "Offenses" line showing error/warning breakdown.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_offenses_line(aggregated_result) #: void # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          errors = aggregated_result.error_count
          warnings = aggregated_result.warning_count
          total = aggregated_result.offense_count
          files_with_offenses = aggregated_result.files_with_offenses_count

          if total.zero?
            summary = colorize("0 offenses", color: :green, bold: true)
          else
            parts = []
            parts << colorize("#{errors} #{pluralize(errors, 'error')}", color: :red, bold: true) if errors.positive?

            if warnings.positive?
              parts << colorize("#{warnings} #{pluralize(warnings, 'warning')}", color: :yellow, bold: true)
            elsif errors.positive?
              parts << colorize("#{warnings} #{pluralize(warnings, 'warning')}", color: :green, bold: true)
            end

            summary = parts.join(" | ")

            if files_with_offenses.positive?
              offense_text = "#{total} #{pluralize(total, 'offense')}"
              file_text = "#{files_with_offenses} #{pluralize(files_with_offenses, 'file')}"
              detail = colorize("(#{offense_text} across #{file_text})", color: :gray, dim: true)
              summary += " #{detail}"
            end
          end

          io.puts " #{pad_label('Offenses')} #{summary}"
        end

        # Prints the "Fixable" line showing autocorrectable offenses.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_fixable_line(aggregated_result) #: void
          total = aggregated_result.offense_count
          fixable = aggregated_result.autofixable_count

          return if total.zero? && fixable.zero?

          total_part = colorize("#{total} #{pluralize(total, 'offense')}", color: :red, bold: true)

          if fixable.positive?
            fixable_part = colorize("#{fixable} autocorrectable using `--fix`", color: :green, bold: true)
            io.puts " #{pad_label('Fixable')} #{total_part} | #{fixable_part}"
          else
            io.puts " #{pad_label('Fixable')} #{total_part}"
          end
        end

        # Prints success message if all files are clean.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_success_message(aggregated_result) #: void
          files_with_offenses = aggregated_result.files_with_offenses_count

          return unless files_with_offenses.zero? && aggregated_result.file_count > 1

          io.puts ""
          checkmark = colorize("✓", color: :green, bold: true)
          message = colorize("All files are clean!", color: :green)
          io.puts " #{checkmark} #{message}"
        end

        # Pads a label to a consistent width.
        #
        # @rbs label: String
        def pad_label(label) #: String
          colorize(label.ljust(12), color: :gray)
        end

        # Applies color and styling to text.
        # Simplified version - only applies colors when TTY is supported.
        #
        # @rbs text: String
        # @rbs color: Symbol? -- :red, :green, :yellow, :cyan, :gray
        # @rbs bold: bool -- make text bold
        # @rbs dim: bool -- make text dimmed
        def colorize(text, color: nil, bold: false, dim: false) #: String # rubocop:disable Metrics/CyclomaticComplexity
          return text unless io.tty?

          codes = []
          codes << 1 if bold
          codes << 2 if dim

          case color
          when :red
            codes << 31
          when :green
            codes << 32
          when :yellow
            codes << 33
          when :cyan
            codes << 36
          when :gray
            codes << 90
          end

          return text if codes.empty?

          "\e[#{codes.join(';')}m#{text}\e[0m"
        end
      end
    end
  end
end
