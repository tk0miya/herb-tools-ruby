# frozen_string_literal: true

module Herb
  module Lint
    # Detects file-level `<%# herb:linter ignore %>` directives.
    # When present anywhere in the source, the entire file is skipped.
    module LinterIgnore
      # Pattern matching the exact linter ignore directive.
      IGNORE_PATTERN = /<%#\s*herb:linter\s+ignore\s*%>/ #: Regexp

      # Returns true if the source contains a linter ignore directive.
      #
      # @rbs source: String
      def self.ignore_file?(source) #: bool
        source.match?(IGNORE_PATTERN)
      end
    end
  end
end
