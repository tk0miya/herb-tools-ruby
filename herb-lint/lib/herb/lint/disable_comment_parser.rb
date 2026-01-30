# frozen_string_literal: true

module Herb
  module Lint
    # Parses `<%# herb:disable ... %>` comments from ERB source text.
    # This module handles collection only — it extracts DisableComment
    # data from source but does not decide how they affect offenses.
    module DisableCommentParser
      # Pattern matching an ERB comment containing a herb:disable directive.
      # Captures the rule list (e.g. "alt-text, html/no-duplicate-id" or "all").
      DISABLE_PATTERN = /<%#\s*herb:disable\s+(.+?)\s*%>/ #: Regexp

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

      # Parse an entire source string and return a disable cache.
      # The cache maps each target line number (the line *after* the comment)
      # to its DisableComment, following the TS convention where
      # `herb:disable` applies to the next line.
      #
      # @rbs source: String
      def self.parse_source(source) #: Hash[Integer, DisableComment]
        cache = {} #: Hash[Integer, DisableComment]
        source.each_line.with_index(1) do |line, line_number|
          comment = parse_line(line, line_number:)
          next unless comment

          target_line = line_number + 1
          cache[target_line] = comment
        end
        cache
      end
    end
  end
end
