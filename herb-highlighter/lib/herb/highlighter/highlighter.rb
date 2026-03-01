# frozen_string_literal: true

module Herb
  module Highlighter
    # Main orchestrator for the herb-highlighter gem.
    # Creates and wires together SyntaxRenderer, DiagnosticRenderer, and FileRenderer.
    # Provides a simple top-level API for highlighting ERB/HTML source.
    # Mirrors TypeScript Highlighter.
    class Highlighter
      private attr_reader :context_lines #: Integer
      private attr_reader :diagnostic_renderer #: DiagnosticRenderer
      private attr_reader :file_renderer #: FileRenderer

      # @rbs file_renderer: FileRenderer
      # @rbs diagnostic_renderer: DiagnosticRenderer
      # @rbs context_lines: Integer
      def initialize(file_renderer: FileRenderer.new, diagnostic_renderer: DiagnosticRenderer.new, context_lines: 2) #: void # rubocop:disable Layout/LineLength
        @context_lines = context_lines
        @file_renderer = file_renderer
        @diagnostic_renderer = diagnostic_renderer
      end

      # Renders a complete source file with line numbers and highlighting.
      #
      # @rbs source: String
      # @rbs focus_line: Integer?
      def highlight_source(source, focus_line: nil) #: String
        file_renderer.render(source, focus_line:, context_lines:)
      end

      # Renders source context for a single offense (used when embedding in other tools).
      #
      # @rbs source_lines: Array[String]
      # @rbs line: Integer
      # @rbs column: Integer
      # @rbs end_line: Integer?
      # @rbs end_column: Integer?
      def render_diagnostic(source_lines, line:, column:, end_line: nil, end_column: nil) #: String
        diagnostic_renderer.render(
          source_lines, line:, column:, end_line:, end_column:
        )
      end
    end
  end
end
