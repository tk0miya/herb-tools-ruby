# frozen_string_literal: true

module Herb
  module Lint
    # Detects herb:disable directives that did not suppress any offense.
    # Used by the Linter after offense filtering to report unnecessary directives.
    class UnnecessaryDirectiveDetector
      RULE_NAME = "herb-disable-comment-unnecessary" #: String

      # @rbs directives: DirectiveParser::Directives
      # @rbs ignored_offenses: Array[Offense]
      def self.detect(directives, ignored_offenses) #: Array[Offense]
        new(directives, ignored_offenses).detect
      end

      # @rbs @directives: DirectiveParser::Directives
      # @rbs @by_line: Hash[Integer, Array[String]]

      # @rbs directives: DirectiveParser::Directives
      # @rbs ignored_offenses: Array[Offense]
      def initialize(directives, ignored_offenses) #: void
        @directives = directives
        @by_line = ignored_offenses.group_by(&:line).transform_values { _1.map(&:rule_name) }
      end

      def detect #: Array[Offense]
        offenses = [] #: Array[Offense]
        @directives.disable_comments.each do |line, comment|
          next unless comment.match
          next if comment.rule_names.empty?

          check_comment(offenses, line, comment)
        end
        offenses
      end

      private

      # @rbs offenses: Array[Offense]
      # @rbs line: Integer
      # @rbs comment: DirectiveParser::DisableComment
      def check_comment(offenses, line, comment) #: void
        suppressed = @by_line[line] || []

        if comment.rule_names.include?("all")
          return if suppressed.any?

          offenses << build_offense(
            "Unnecessary herb:disable directive (no offenses were suppressed)",
            comment.content_location
          )
        else
          check_rule_names(offenses, comment, suppressed)
        end
      end

      # @rbs offenses: Array[Offense]
      # @rbs comment: DirectiveParser::DisableComment
      # @rbs suppressed: Array[String]
      def check_rule_names(offenses, comment, suppressed) #: void
        comment.rule_name_details.each do |detail|
          next if suppressed.include?(detail.name)

          offenses << build_offense(
            "Unnecessary herb:disable for rule '#{detail.name}' (no matching offense)",
            build_detail_location(comment, detail)
          )
        end
      end

      # @rbs message: String
      # @rbs location: Herb::Location
      def build_offense(message, location) #: Offense
        Offense.new(rule_name: RULE_NAME, message:, severity: "warning", location:)
      end

      # @rbs comment: DirectiveParser::DisableComment
      # @rbs detail: DirectiveParser::DisableRuleName
      def build_detail_location(comment, detail) #: Herb::Location
        content_start = comment.content_location.start
        column = content_start.column + detail.offset
        start_pos = Herb::Position.new(content_start.line, column)
        end_pos = Herb::Position.new(content_start.line, column + detail.length)
        Herb::Location.new(start_pos, end_pos)
      end
    end
  end
end
