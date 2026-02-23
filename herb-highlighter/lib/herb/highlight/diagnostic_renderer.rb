# frozen_string_literal: true

module Herb
  module Highlight
    # Renders source code context around a single offense.
    # Shows N context lines before and after the offense line, each prefixed with
    # a formatted line number. Appends a caret row below the offense line.
    # Mirrors TypeScript DiagnosticRenderer.
    #
    # This class does NOT render the offense header (location, message, rule name).
    # The header is the formatter's responsibility.
    class DiagnosticRenderer
      # @rbs syntax_renderer: SyntaxRenderer
      # @rbs context_lines: Integer
      # @rbs tty: bool -- when false, no ANSI codes are emitted
      def initialize(syntax_renderer: SyntaxRenderer.new, context_lines: 2, tty: true) #: void
        @syntax_renderer = syntax_renderer
        @context_lines = context_lines
        @tty = tty
      end

      # Renders source context for a single offense.
      #
      # @rbs source_lines: Array[String]
      # @rbs line: Integer -- 1-based offense line number
      # @rbs column: Integer -- 1-based offense column
      # @rbs end_line: Integer? -- 1-based end line (nil = same as line)
      # @rbs end_column: Integer? -- 1-based end column (nil = single char)
      def render(source_lines, line:, column:, end_line: nil, end_column: nil) #: String
        width = line_number_width(source_lines, line)
        start_context = [1, line - @context_lines].max
        end_context = [source_lines.size, line + @context_lines].min

        output = +""
        (start_context..end_context).each do |num|
          output << render_line(source_lines, num, line, width)
          output << caret_row(width, column, line, end_line, end_column) if num == line
        end
        output
      end

      private

      # @rbs source_lines: Array[String]
      # @rbs line: Integer
      def line_number_width(source_lines, line) #: Integer
        end_display = [source_lines.size, line + @context_lines].min
        end_display.to_s.length
      end

      # @rbs source_lines: Array[String]
      # @rbs num: Integer
      # @rbs offense_line: Integer
      # @rbs width: Integer
      def render_line(source_lines, num, offense_line, width) #: String
        content = (source_lines[num - 1] || "").chomp
        highlighted = @syntax_renderer.render(content)

        if num == offense_line
          line_num_str = colorize(num.to_s.rjust(width), "brightRed")
          separator = colorize(" | ", "brightRed")
        else
          line_num_str = colorize(num.to_s.rjust(width), "gray")
          separator = colorize(" | ", "gray")
        end

        "  #{line_num_str}#{separator}#{highlighted}\n"
      end

      # @rbs width: Integer
      # @rbs column: Integer
      # @rbs line: Integer
      # @rbs end_line: Integer?
      # @rbs end_column: Integer?
      def caret_row(width, column, line, end_line, end_column) #: String
        length = caret_length(column, line, end_line, end_column)
        caret = colorize("^" * length, "brightRed")
        padding = " " * [column - 1, 0].max
        "  #{' ' * width} | #{padding}#{caret}\n"
      end

      # @rbs column: Integer
      # @rbs line: Integer
      # @rbs end_line: Integer?
      # @rbs end_column: Integer?
      def caret_length(column, line, end_line, end_column) #: Integer
        resolved_end_line = end_line || line
        return 1 unless resolved_end_line == line
        return 1 unless end_column

        [end_column - column + 1, 1].max
      end

      # Applies color if TTY mode is enabled.
      #
      # @rbs text: String
      # @rbs color: String
      def colorize(text, color) #: String
        @tty ? Color.colorize(text, color) : text
      end
    end
  end
end
