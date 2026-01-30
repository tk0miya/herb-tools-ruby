# frozen_string_literal: true

module Herb
  module Lint
    # Holds parsed directive data and provides judgment methods.
    # This is the data management + judgment layer — it holds the
    # collection of DisableComment objects and answers questions
    # about which rules are disabled at which lines.
    class DisableDirectives
      attr_reader :comments #: Array[DisableComment]

      # @rbs comments: Array[DisableComment]
      # @rbs ignore_file: bool
      def initialize(comments:, ignore_file:) #: void
        @comments = comments
        @ignore_file = ignore_file
        @cache = build_cache #: Hash[Integer, DisableComment]
      end

      # Returns true if the file should be skipped entirely.
      def ignore_file? #: bool
        @ignore_file
      end

      # Returns true if the given rule is disabled at the given line.
      # @rbs line: Integer -- 1-based line number
      # @rbs rule_name: String
      def rule_disabled?(line, rule_name) #: bool
        comment = @cache[line]
        return false unless comment

        comment.disables_rule?(rule_name)
      end

      private

      # Build a cache mapping target line (the line after each comment)
      # to its DisableComment.
      def build_cache #: Hash[Integer, DisableComment]
        cache = {} #: Hash[Integer, DisableComment]
        comments.each do |comment|
          target_line = comment.line + 1
          cache[target_line] = comment
        end
        cache
      end
    end
  end
end
