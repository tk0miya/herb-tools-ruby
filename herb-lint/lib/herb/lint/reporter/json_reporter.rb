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

        # Builds the full output hash to match TypeScript herb linter format.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_output(aggregated_result) #: Hash[String, untyped]
          {
            "offenses" => build_offenses(aggregated_result),
            "summary" => build_summary(aggregated_result),
            "timing" => nil,
            "completed" => true,
            "clean" => aggregated_result.offense_count.zero?,
            "message" => nil
          }
        end

        # Builds flat offenses array from all files.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_offenses(aggregated_result) #: Array[Hash[String, untyped]]
          aggregated_result.results.flat_map do |result|
            result.unfixed_offenses.map { |offense| build_offense(offense, result.file_path) }
          end
        end

        # Builds a single offense hash.
        #
        # @rbs offense: Offense
        # @rbs file_path: String
        def build_offense(offense, file_path) #: Hash[String, untyped]
          {
            "filename" => file_path,
            "message" => offense.message,
            "location" => {
              "start" => { "line" => offense.line, "column" => offense.column },
              "end" => { "line" => offense.location.end.line, "column" => offense.location.end.column }
            },
            "severity" => offense.severity,
            "code" => offense.rule_name,
            "source" => "Herb Linter"
          }
        end

        # Builds the summary hash to match TypeScript format.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_summary(aggregated_result) #: Hash[String, Integer]
          files_with_offenses = aggregated_result.results.count { |result| result.unfixed_offenses.any? }

          {
            "filesChecked" => aggregated_result.file_count,
            "filesWithOffenses" => files_with_offenses,
            "totalErrors" => aggregated_result.error_count,
            "totalWarnings" => aggregated_result.warning_count,
            "totalInfo" => aggregated_result.info_count,
            "totalHints" => aggregated_result.hint_count,
            "totalIgnored" => 0,
            "totalOffenses" => aggregated_result.offense_count,
            "ruleCount" => 0
          }
        end
      end
    end
  end
end
