# frozen_string_literal: true

require "json"
require_relative "base"

module Herb
  module Lint
    module Formatter
      # Formatter that outputs linting results in JSON format.
      class JsonFormatter < Base
        # Reports the aggregated linting result as JSON.
        # When aggregated_result.completed? is false, outputs the disabled result.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          io.puts JSON.generate(build_output(aggregated_result))
        end

        private

        # Builds the full output hash to match TypeScript herb linter format.
        # Handles both completed and disabled (completed: false) results.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_output(aggregated_result) #: Hash[String, untyped]
          if aggregated_result.completed?
            {
              "offenses" => build_offenses(aggregated_result),
              "summary" => build_summary(aggregated_result),
              "timing" => build_timing(aggregated_result),
              "completed" => true,
              "clean" => aggregated_result.offense_count.zero?,
              "message" => nil
            }
          else
            {
              "offenses" => [],
              "summary" => build_summary(aggregated_result),
              "timing" => build_timing(aggregated_result),
              "completed" => false,
              "clean" => nil,
              "message" => aggregated_result.message
            }
          end
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

        # Builds the timing hash to match TypeScript format, or nil if not tracked.
        #
        # @rbs aggregated_result: AggregatedResult
        def build_timing(aggregated_result) #: Hash[String, untyped]?
          return nil unless aggregated_result.duration

          {
            "startTime" => aggregated_result.start_time&.iso8601,
            "duration" => aggregated_result.duration
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
            "totalIgnored" => aggregated_result.ignored_count,
            "totalOffenses" => aggregated_result.offense_count,
            "ruleCount" => aggregated_result.rule_count
          }
        end
      end
    end
  end
end
