# frozen_string_literal: true

module Herb
  module Lint
    module Reporter
      # Simple reporter that outputs linting results in a human-readable format.
      class SimpleReporter
        attr_reader :io #: IO

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          @io = io
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
          io.puts format(
            "  %<line>d:%<column>d  %-8<severity>s %<message>s  %<rule_name>s",
            line: offense.line,
            column: offense.column,
            severity: offense.severity,
            message: offense.message,
            rule_name: offense.rule_name
          )
        end

        # Prints the summary of all offenses.
        #
        # @rbs aggregated_result: AggregatedResult
        def print_summary(aggregated_result) #: void
          total = aggregated_result.offense_count
          errors = aggregated_result.error_count
          warnings = aggregated_result.warning_count
          files = aggregated_result.file_count

          io.puts format_summary(total, errors, warnings, files)
        end

        # Formats the summary string.
        #
        # @rbs total: Integer
        # @rbs errors: Integer
        # @rbs warnings: Integer
        # @rbs files: Integer
        def format_summary(total, errors, warnings, files) #: String
          problem_word = total == 1 ? "problem" : "problems"
          error_word = errors == 1 ? "error" : "errors"
          warning_word = warnings == 1 ? "warning" : "warnings"
          file_word = files == 1 ? "file" : "files"

          "#{total} #{problem_word} (#{errors} #{error_word}, #{warnings} #{warning_word}) " \
            "in #{files} #{file_word}"
        end
      end
    end
  end
end
