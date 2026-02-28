# frozen_string_literal: true

module Herb
  module Highlight
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
      #
      # @rbs source: String
      # @rbs focus_line: Integer? -- 1-based line to render in red+bold (nil = no focus)
      def render(source, focus_line: nil) #: String
        return "" if source.empty?

        lines = source.lines
        width = lines.size.to_s.length

        output = +""
        lines.each_with_index do |line, index|
          num = index + 1
          output << render_line(num, line.chomp, focus_line, width)
        end
        output
      end

      private

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
