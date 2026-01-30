# frozen_string_literal: true

module Herb
  module Lint
    # Parses directive comments from ERB source text.
    # This module handles parsing only — it extracts data from source
    # but does not decide how directives affect offenses.
    module DisableCommentParser
      # Pattern matching an ERB comment containing a herb:disable directive.
      # Captures the rule list (e.g. "alt-text, html/no-duplicate-id" or "all").
      DISABLE_PATTERN = /<%#\s*herb:disable\s+(.+?)\s*%>/ #: Regexp

      # Pattern matching the file-level linter ignore directive.
      IGNORE_PATTERN = /<%#\s*herb:linter\s+ignore\s*%>/ #: Regexp

      # Parse an entire source string and return a DisableDirectives object.
      #
      # @rbs source: String
      def self.parse(source) #: DisableDirectives
        comments = [] #: Array[DisableComment]
        ignore_file = false

        source.each_line.with_index(1) do |line, line_number|
          ignore_file = true if line.match?(IGNORE_PATTERN)

          comment = parse_line(line, line_number:)
          comments << comment if comment
        end

        DisableDirectives.new(comments:, ignore_file:)
      end

      # Parse a single source line for a disable comment.
      # Returns nil if the line does not contain a disable directive.
      #
      # @rbs line: String -- a single line of source text
      # @rbs line_number: Integer -- 1-based line number
      def self.parse_line(line, line_number:) #: DisableComment?
        match = line.match(DISABLE_PATTERN)
        return nil unless match

        rules_string = match[1] || ""
        rule_names = rules_string.split(",").map(&:strip).reject(&:empty?)
        DisableComment.new(rule_names:, line: line_number)
      end
    end
  end
end
