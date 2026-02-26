# frozen_string_literal: true

module Herb
  module Highlight
    # Renders source code context around a single offense with line numbers and a caret indicator.
    # Shows N context lines before and after the offense line, each prefixed with a formatted
    # line number. Appends a caret (^) row below the offense line pointing to the column.
    # Mirrors TypeScript DiagnosticRenderer.
    #
    # This class does NOT render the offense header (location, message, rule name). The header is
    # the formatter's responsibility (DetailedFormatter).
    class DiagnosticRenderer
      # @rbs @syntax_renderer: SyntaxRenderer
      # @rbs @context_lines: Integer
      # @rbs @tty: bool

      # @rbs syntax_renderer: SyntaxRenderer
      # @rbs context_lines: Integer
      # @rbs tty: bool -- when false, no ANSI codes are emitted
      def initialize(syntax_renderer: SyntaxRenderer.new, context_lines: 2, tty: true) #: void
        @syntax_renderer = syntax_renderer
        @context_lines = context_lines
        @tty = tty
      end

      # Renders source context around the given offense position.
      #
      # @rbs source_lines: Array[String]
      # @rbs line: Integer -- 1-based offense line number
      # @rbs column: Integer -- 1-based offense column
      # @rbs end_line: Integer? -- 1-based end line (nil = same as line)
      # @rbs end_column: Integer? -- 1-based end column (nil = column + 1)
      def render(source_lines, line:, column:, end_line: nil, end_column: nil) #: String
        # Default end_column to column+1 (matches TypeScript convention: exclusive end position).
        # This produces a 2-caret indicator for nil-range offenses rather than a single caret.
        end_column ||= column + 1

        start_display_line = [1, line - @context_lines].max
        end_display_line = [source_lines.size, line + @context_lines].min
        width = end_display_line.to_s.length

        output = +""

        (start_display_line..end_display_line).each do |num|
          output << render_source_line(num, source_lines, line, width)
          output << render_caret_row(column, line, end_line, end_column, width) if num == line
        end

        output
      end

      private

      # @rbs num: Integer
      # @rbs source_lines: Array[String]
      # @rbs offense_line: Integer
      # @rbs width: Integer
      def render_source_line(num, source_lines, offense_line, width) #: String
        content = (source_lines[num - 1] || "").chomp
        highlighted_content = @syntax_renderer.render(content)

        if num == offense_line
          line_num_str = colorize(num.to_s.rjust(width), "brightRed")
          separator = colorize(" | ", "brightRed")
        else
          line_num_str = colorize(num.to_s.rjust(width), "gray")
          separator = colorize(" | ", "gray")
        end

        "  #{line_num_str}#{separator}#{highlighted_content}\n"
      end

      # @rbs column: Integer
      # @rbs line: Integer
      # @rbs end_line: Integer?
      # @rbs end_column: Integer
      # @rbs width: Integer
      def render_caret_row(column, line, end_line, end_column, width) #: String
        caret_length = if end_line.nil? || end_line == line
                         [end_column - column + 1, 1].max
                       else
                         1
                       end
        caret = colorize("^" * caret_length, "brightRed")
        "  #{' ' * width} | #{' ' * [column - 1, 0].max}#{caret}\n"
      end

      # @rbs text: String
      # @rbs color: String
      def colorize(text, color) #: String
        @tty ? Color.colorize(text, color) : text
      end
    end
  end
end
