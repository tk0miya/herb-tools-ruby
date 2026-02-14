# frozen_string_literal: true

module Herb
  module Format
    # Provides contextual information during formatting and rewriting.
    Context = Data.define(
      :file_path,     #: String
      :source,        #: String
      :config         #: Herb::Config::FormatterConfig
    )

    # :nodoc:
    class Context
      attr_reader :source_lines #: Array[String]

      # @rbs file_path: String
      # @rbs source: String
      # @rbs config: Herb::Config::FormatterConfig
      def initialize(file_path:, source:, config:) #: void
        # Compute and cache source_lines before freezing
        @source_lines = source.lines(chomp: false)
        super
      end

      def indent_width = config.indent_width #: Integer

      def max_line_length = config.max_line_length #: Integer

      # @rbs line: Integer
      def source_line(line) #: String
        return "" if line < 1 || line > line_count

        source_lines[line - 1] || ""
      end

      def line_count = source_lines.size #: Integer
    end
  end
end
