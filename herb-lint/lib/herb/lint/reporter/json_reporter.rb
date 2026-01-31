# frozen_string_literal: true

require "json"

module Herb
  module Lint
    module Reporter
      # Reporter that outputs linting results in JSON format.
      class JsonReporter
        attr_reader :io #: IO

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          @io = io
        end

        # Reports the aggregated linting result as JSON.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          io.puts JSON.generate(build_output(aggregated_result))
        end

        private

        # Builds the full output hash.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_output(aggregated_result) #: Hash[String, untyped]
          {
            "files" => aggregated_result.results.map { |result| build_file(result) },
            "summary" => build_summary(aggregated_result)
          }
        end

        # Builds a single file entry with its offenses.
        #
        # @rbs result: LintResult
        def build_file(result) #: Hash[String, untyped]
          {
            "path" => result.file_path,
            "offenses" => result.offenses.map do |offense|
              {
                "rule" => offense.rule_name,
                "severity" => offense.severity,
                "message" => offense.message,
                "line" => offense.line,
                "column" => offense.column,
                "endLine" => offense.location.end.line,
                "endColumn" => offense.location.end.column,
                "fixable" => false
              }
            end
          }
        end

        # Builds the summary hash.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_summary(aggregated_result) #: Hash[String, Integer]
          {
            "fileCount" => aggregated_result.file_count,
            "offenseCount" => aggregated_result.offense_count,
            "errorCount" => aggregated_result.error_count,
            "warningCount" => aggregated_result.warning_count,
            "fixableCount" => 0
          }
        end
      end
    end
  end
end
