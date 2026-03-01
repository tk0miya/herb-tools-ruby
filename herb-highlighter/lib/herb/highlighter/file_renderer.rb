# frozen_string_literal: true

module Herb
  module Highlighter
    # Renders a complete ERB/HTML source file with line numbers and syntax highlighting.
    # Used by the herb-highlight CLI to display a highlighted file.
    # Mirrors TypeScript FileRenderer.
    #
    # Not used by herb-lint's DetailedFormatter (which uses DiagnosticRenderer instead).
    class FileRenderer
      # @rbs @syntax_renderer: SyntaxRenderer
      # @rbs @tty: bool

      # @rbs syntax_renderer: SyntaxRenderer
      # @rbs tty: bool
      def initialize(syntax_renderer: SyntaxRenderer.new, tty: true) #: void
        @syntax_renderer = syntax_renderer
        @tty = tty
      end

      # Renders all lines of source with sequential line numbers.
      # Each line ends with a newline.
      # When focus_line is given, only renders lines within context_lines of the focus line.
      #
      # @rbs source: String
      # @rbs focus_line: Integer? -- 1-based line to render in cyan+bold (nil = no focus, renders all)
      # @rbs context_lines: Integer -- number of context lines around focus_line (only used when focus_line is set)
      def render(source, focus_line: nil, context_lines: 2) #: String
        return "" if source.empty?

        lines = source.lines
        width = lines.size.to_s.length

        output = +""
        render_range(lines.size, focus_line, context_lines).each do |num|
          output << render_line(num, lines[num - 1].chomp, focus_line, width)
        end
        output
      end

      private

      # Returns the range of line numbers to render.
      # When focus_line is set, clamps the window to the file bounds.
      # When focus_line is nil, returns the full range.
      #
      # @rbs total_lines: Integer
      # @rbs focus_line: Integer?
      # @rbs context_lines: Integer
      def render_range(total_lines, focus_line, context_lines) #: Range[Integer]
        return (1..total_lines) unless focus_line

        start_line = [1, focus_line - context_lines].max
        end_line = [total_lines, focus_line + context_lines].min
        (start_line..end_line)
      end

      # Renders a single line with line number prefix.
      # Focus line uses cyan arrow prefix and bold line number; all other lines use gray and dim.
      #
      # @rbs num: Integer
      # @rbs content: String
      # @rbs focus_line: Integer?
      # @rbs width: Integer
      def render_line(num, content, focus_line, width) #: String
        highlighted = @syntax_renderer.render(content)
        num_str = num.to_s.rjust(width)
        focus = (num == focus_line)
        sep = colorize("│", "gray")

        if focus
          prefix = colorize("  → ", "cyan")
          line_num = colorize(num_str, "bold")
          "#{prefix}#{line_num} #{sep} #{highlighted}\n"
        else
          line_num = colorize(num_str, "gray")
          "    #{line_num} #{sep} #{dim(highlighted)}\n"
        end
      end

      # Applies color/style if TTY mode is enabled.
      #
      # @rbs text: String
      # @rbs color: String
      def colorize(text, color) #: String
        return text unless @tty

        Color.colorize(text, color)
      end

      # Wraps text in ANSI dim codes if TTY mode is enabled.
      #
      # @rbs text: String
      def dim(text) #: String
        return text unless @tty

        Color.colorize(text, "dim")
      end
    end
  end
end
