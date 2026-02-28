# frozen_string_literal: true

module Herb
  module Highlight
    # Renders source code context around a single offense.
    # Shows N context lines before and after the offense line, each prefixed
    # with a formatted line number. Appends a pointer (~) row below the offense
    # line pointing to the specific column.
    # Mirrors TypeScript DiagnosticRenderer.
    #
    # Does NOT render the offense header (location, message, rule name).
    # The header is the formatter's responsibility (e.g. DetailedFormatter).
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

      # Renders source code context around a single offense.
      # Returns the formatted string with line numbers, source lines, and pointer.
      #
      # @rbs source_lines: Array[String]
      # @rbs line: Integer -- 1-based offense line number
      # @rbs column: Integer -- 1-based offense column
      # @rbs severity: String -- "error", "warning", "info", "hint"
      # @rbs end_line: Integer? -- 1-based end line (nil = same as line)
      # @rbs end_column: Integer? -- 1-based end column (nil = column)
      def render(source_lines, line:, column:, severity: "error", end_line: nil, end_column: nil) #: String
        end_display_line = [source_lines.size, line + @context_lines].min
        start_line = [1, line - @context_lines].max
        width = end_display_line.to_s.length
        pointer_len = compute_pointer_length(line, column, end_line, end_column)
        sev_color = Color.severity_color(severity)

        output = +""
        (start_line..end_display_line).each do |num|
          output << render_line(source_lines, num, line, column, width, pointer_len, sev_color)
        end
        output
      end

      private

      # Renders a single source line with line number, separator, and optional pointer.
      #
      # @rbs source_lines: Array[String]
      # @rbs num: Integer
      # @rbs offense_line: Integer
      # @rbs column: Integer
      # @rbs width: Integer
      # @rbs pointer_len: Integer
      # @rbs sev_color: String
      def render_line(source_lines, num, offense_line, column, width, pointer_len, sev_color) #: String
        content = (source_lines[num - 1] || "").chomp
        offense = (num == offense_line)
        result = format_source_line(num, content, offense, width, sev_color)
        result << render_pointer(width, column, pointer_len, sev_color) if offense
        result
      end

      # Formats one source line: prefix + line number + separator + content.
      # Offense line: arrow prefix in severity color, bold line number.
      # Context line: plain indent, gray line number, dimmed content.
      #
      # @rbs num: Integer
      # @rbs content: String
      # @rbs offense: bool
      # @rbs width: Integer
      # @rbs sev_color: String
      def format_source_line(num, content, offense, width, sev_color) #: String
        highlighted = @syntax_renderer.render(content)
        num_str = num.to_s.rjust(width)
        sep = tty_colorize("│", "gray")

        if offense
          prefix = tty_colorize("  → ", sev_color)
          line_num = tty_colorize(num_str, "bold")
          "#{prefix}#{line_num} #{sep} #{highlighted}\n"
        else
          line_num = tty_colorize(num_str, "gray")
          "    #{line_num} #{sep} #{tty_dim(highlighted)}\n"
        end
      end

      # Builds the pointer row (~) below the offense line.
      #
      # @rbs width: Integer
      # @rbs column: Integer
      # @rbs pointer_len: Integer
      # @rbs sev_color: String
      def render_pointer(width, column, pointer_len, sev_color) #: String
        sep = tty_colorize("│", "gray")
        pointer = tty_colorize("~" * pointer_len, sev_color)
        "    #{' ' * width} #{sep} #{' ' * [column - 1, 0].max}#{pointer}\n"
      end

      # Computes the pointer length based on offense location.
      #
      # @rbs line: Integer
      # @rbs column: Integer
      # @rbs end_line: Integer?
      # @rbs end_column: Integer?
      def compute_pointer_length(line, column, end_line, end_column) #: Integer
        resolved_end_column = end_column || column
        if end_line.nil? || end_line == line
          [resolved_end_column - column + 1, 1].max
        else
          1
        end
      end

      # Applies color/style if TTY mode is enabled.
      #
      # @rbs text: String
      # @rbs color: String
      def tty_colorize(text, color) #: String
        return text unless @tty

        Color.colorize(text, color)
      end

      # Wraps text in ANSI dim codes if TTY mode is enabled.
      # Simplified version of TypeScript applyDimToStyledText.
      #
      # @rbs text: String
      def tty_dim(text) #: String
        return text unless @tty

        Color.colorize(text, "dim")
      end
    end
  end
end
