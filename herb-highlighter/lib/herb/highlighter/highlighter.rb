# frozen_string_literal: true

module Herb
  module Highlighter
    # Main orchestrator for the herb-highlighter gem.
    # Creates and wires together SyntaxRenderer, DiagnosticRenderer, and FileRenderer.
    # Provides a simple top-level API for highlighting ERB/HTML source.
    # Mirrors TypeScript Highlighter.
    class Highlighter
      private attr_reader :diagnostic_renderer #: DiagnosticRenderer
      private attr_reader :file_renderer #: FileRenderer
      private attr_reader :syntax_renderer #: SyntaxRenderer

      # @rbs theme_name: String? -- nil = plain text (no highlighting)
      # @rbs context_lines: Integer
      # @rbs tty: bool
      def initialize(theme_name: nil, context_lines: 2, tty: true) #: void
        @syntax_renderer = SyntaxRenderer.new(theme_name:)
        @file_renderer = FileRenderer.new(syntax_renderer: @syntax_renderer, tty:)
        @diagnostic_renderer = DiagnosticRenderer.new(
          syntax_renderer: @syntax_renderer,
          context_lines:,
          tty:
        )
      end

      # Renders a complete source file with line numbers and highlighting.
      #
      # @rbs source: String
      # @rbs focus_line: Integer?
      def highlight_source(source, focus_line: nil) #: String
        file_renderer.render(source, focus_line:)
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
