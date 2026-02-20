# frozen_string_literal: true

require_relative "../console_utils"
require_relative "../string_utils"

module Herb
  module Lint
    module Reporter
      # Summary reporter that outputs aggregated linting results.
      # This class is used by formatters to display summary information.
      class SummaryReporter # rubocop:disable Metrics/ClassLength
        include ConsoleUtils
        include StringUtils

        attr_reader :io #: IO
        attr_reader :show_timing #: bool

        # @rbs io: IO
        # @rbs show_timing: bool -- when false, suppresses timing display
        def initialize(io: $stdout, show_timing: true) #: void
          @io = io
          @show_timing = show_timing
        end

        # Displays a summary of the aggregated linting result.
        #
        # @rbs aggregated_result: AggregatedResult
        def display_summary(aggregated_result) #: void
          io.puts "\n"
          io.puts colorize(" Summary:", bold: true)

          print_checked_line(aggregated_result)
          print_files_line(aggregated_result) if aggregated_result.file_count > 1
          print_offenses_line(aggregated_result)
          print_fixable_line(aggregated_result)
          print_timing_line(aggregated_result) if show_timing && aggregated_result.duration
          print_success_message(aggregated_result)
        end

        private

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

        # Prints timing lines showing start time and total execution duration.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_timing_line(aggregated_result) #: void
          return unless aggregated_result.duration

          if aggregated_result.start_time
            time_str = aggregated_result.start_time.strftime("%H:%M:%S")
            io.puts " #{pad_label('Start at')} #{colorize(time_str, color: :cyan)}"
          end

          rule_count = aggregated_result.rule_count
          rule_str = colorize("(#{rule_count} #{pluralize(rule_count, 'rule')})", color: :gray, dim: true)
          io.puts " #{pad_label('Duration')} #{colorize("#{aggregated_result.duration}ms", color: :cyan)} #{rule_str}"
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
