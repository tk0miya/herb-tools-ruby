# frozen_string_literal: true

module Herb
  module Highlighter
    # ANSI color utilities for syntax highlighting.
    # Converts hex/named colors to escape sequences and applies them to text.
    # Mirrors TypeScript color.ts. All methods are module-level (no instances).
    module Color
      # All named ANSI colors accepted by themes (mirrors TypeScript color.ts `colors` object).
      # Keys match the TypeScript names exactly (camelCase where TypeScript uses camelCase).
      NAMED_COLORS = {
        "reset" => "\e[0m",
        "bold" => "\e[1m",
        "dim" => "\e[2m",
        "black" => "\e[30m",
        "red" => "\e[31m",
        "green" => "\e[32m",
        "yellow" => "\e[33m",
        "blue" => "\e[34m",
        "magenta" => "\e[35m",
        "cyan" => "\e[36m",
        "white" => "\e[37m",
        "gray" => "\e[90m",
        "brightRed" => "\e[91m",
        "brightGreen" => "\e[92m",
        "brightYellow" => "\e[93m",
        "brightBlue" => "\e[94m",
        "brightMagenta" => "\e[95m",
        "brightCyan" => "\e[96m",
        "brightWhite" => "\e[97m",
        "bgBlack" => "\e[40m",
        "bgRed" => "\e[41m",
        "bgGreen" => "\e[42m",
        "bgYellow" => "\e[43m",
        "bgBlue" => "\e[44m",
        "bgMagenta" => "\e[45m",
        "bgCyan" => "\e[46m",
        "bgWhite" => "\e[47m",
        "bgGray" => "\e[100m",
        "bgBrightBlack" => "\e[100m"
      }.freeze #: Hash[String, String]

      # Converts a color value to an ANSI foreground escape sequence.
      # Returns nil for unknown/unsupported color names.
      #
      # @rbs color: String -- hex "#RRGGBB" or named ANSI color
      def self.ansi_code(color) #: String?
        if color.start_with?("#") && color.length == 7
          r = color[1..2].to_i(16)
          g = color[3..4].to_i(16)
          b = color[5..6].to_i(16)
          "\e[38;2;#{r};#{g};#{b}m"
        else
          NAMED_COLORS[color]
        end
      end

      # Converts a color value to an ANSI background escape sequence.
      # Returns nil for unknown/unsupported color names.
      #
      # @rbs color: String
      def self.background_ansi_code(color) #: String?
        if color.start_with?("#") && color.length == 7
          r = color[1..2].to_i(16)
          g = color[3..4].to_i(16)
          b = color[5..6].to_i(16)
          "\e[48;2;#{r};#{g};#{b}m"
        else
          NAMED_COLORS[color]
        end
      end

      # Applies ANSI foreground (and optional background) color to text.
      # Respects the NO_COLOR environment variable: if ENV.key?("NO_COLOR"), returns text unchanged.
      #
      # @rbs text: String
      # @rbs color: String -- hex or named color name
      # @rbs background_color: String? -- optional background color (hex or named)
      def self.colorize(text, color, background_color: nil) #: String
        return text if ENV.key?("NO_COLOR")

        foreground_escape = ansi_code(color)
        return text if foreground_escape.nil?

        background_escape = background_color ? (background_ansi_code(background_color) || "") : ""
        "#{background_escape}#{foreground_escape}#{text}\e[0m"
      end

      # Maps a diagnostic severity string to a named color.
      # Used by formatters to color severity labels and symbols.
      #
      # @rbs severity: String
      def self.severity_color(severity) #: String
        case severity
        when "error" then "brightRed"
        when "info" then "cyan"
        when "hint" then "gray"
        else "brightYellow"
        end
      end
    end
  end
end
