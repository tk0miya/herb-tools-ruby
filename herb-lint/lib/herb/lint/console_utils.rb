# frozen_string_literal: true

module Herb
  module Lint
    # Utilities for console output formatting and colorization.
    module ConsoleUtils
      # @rbs! type color = :red | :green | :yellow | :cyan | :gray

      # Applies color and styling to text.
      # Only applies colors when tty is true.
      #
      # @rbs text: String
      # @rbs color: color? -- :red, :green, :yellow, :cyan, :gray
      # @rbs bold: bool -- make text bold
      # @rbs dim: bool -- make text dimmed
      # @rbs tty: bool -- whether the output is a TTY
      def colorize(text, color: nil, bold: false, dim: false, tty: true) #: String # rubocop:disable Metrics/CyclomaticComplexity
        return text unless tty

        codes = []
        codes << 1 if bold
        codes << 2 if dim

        case color
        when :red
          codes << 31
        when :green
          codes << 32
        when :yellow
          codes << 33
        when :cyan
          codes << 36
        when :gray
          codes << 90
        end

        return text if codes.empty?

        "\e[#{codes.join(';')}m#{text}\e[0m"
      end
    end
  end
end
