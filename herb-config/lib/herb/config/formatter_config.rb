# frozen_string_literal: true

module Herb
  module Config
    # Provides access to formatter-specific configuration.
    class FormatterConfig
      # @rbs config_hash: Hash[String, untyped] -- the full configuration hash
      def initialize(config_hash) #: void
        @config = config_hash
      end

      # Returns whether the formatter is enabled.
      # Defaults to false if not configured.
      def enabled #: bool
        formatter_config.fetch("enabled", false)
      end

      # Returns the file patterns to include in formatting.
      # Merges patterns from both the top-level 'files' section and 'formatter' section.
      def include_patterns #: Array[String]
        files_config.fetch("include", []) + formatter_config.fetch("include", [])
      end

      # Returns the file patterns to exclude from formatting.
      # If formatter.exclude is specified, it takes precedence (override behavior).
      # Otherwise, falls back to files.exclude.
      def exclude_patterns #: Array[String]
        formatter_config["exclude"] || files_config["exclude"] || []
      end

      # Returns the indent width (number of spaces per indentation level).
      # Defaults to 2 if not configured.
      def indent_width #: Integer
        formatter_config.fetch("indentWidth", 2)
      end

      # Returns the maximum line length before wrapping.
      # Defaults to 80 if not configured.
      def max_line_length #: Integer
        formatter_config.fetch("maxLineLength", 80)
      end

      # Returns the pre-format rewriters to run (in order) before formatting the AST.
      # Defaults to empty array if not configured.
      def rewriter_pre #: Array[String]
        formatter_config.dig("rewriter", "pre") || []
      end

      # Returns the post-format rewriters to run (in order) after formatting the document.
      # Defaults to empty array if not configured.
      def rewriter_post #: Array[String]
        formatter_config.dig("rewriter", "post") || []
      end

      private

      attr_reader :config #: Hash[String, untyped]

      def formatter_config #: Hash[String, untyped]
        config["formatter"] || {}
      end

      def files_config #: Hash[String, untyped]
        config["files"] || {}
      end
    end
  end
end
