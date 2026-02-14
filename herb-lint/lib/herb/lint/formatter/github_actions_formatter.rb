# frozen_string_literal: true

require_relative "base"

module Herb
  module Lint
    module Formatter
      # Formatter that outputs linting results as GitHub Actions workflow commands.
      class GitHubActionsFormatter < Base
        # Reports the aggregated linting result as GitHub Actions annotations.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          aggregated_result.results.each do |result|
            result.unfixed_offenses.each do |offense|
              io.puts format_annotation(result.file_path, offense)
            end
          end
        end

        private

        # Formats a single offense as a GitHub Actions annotation.
        #
        # @rbs file_path: String
        # @rbs offense: Offense
        def format_annotation(file_path, offense) #: String
          level = map_severity(offense.severity)
          message = "#{offense.message} (#{offense.rule_name})"

          "::#{level} file=#{file_path},line=#{offense.line},col=#{offense.column}::#{message}"
        end

        # Maps lint severity to GitHub Actions annotation level.
        #
        # @rbs severity: String
        def map_severity(severity) #: String
          case severity
          when "error"
            "error"
          when "warning"
            "warning"
          else
            "notice"
          end
        end
      end
    end
  end
end
