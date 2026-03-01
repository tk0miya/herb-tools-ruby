# frozen_string_literal: true

require "json"

module Herb
  module Highlighter
    # Built-in theme store for syntax highlighting.
    # Supports loading custom themes from JSON files.
    # Mirrors TypeScript themes.ts. All state and methods are class-level (no instances).
    module Themes
      # Default theme name used when no theme is specified.
      DEFAULT_THEME = "onedark" #: String

      # @rbs @themes: Hash[String, Hash[String, String?]]

      @themes = {}

      class << self
        # Returns all built-in theme names.
        def names #: Array[String]
          @themes.keys
        end

        # Returns whether name is a registered built-in theme.
        # Mirrors TypeScript isValidTheme.
        #
        # @rbs name: String
        def valid?(name) #: bool
          @themes.key?(name)
        end

        # Returns whether input is NOT a registered built-in theme (i.e. a custom theme path).
        # Mirrors TypeScript isCustomTheme.
        #
        # @rbs input: String
        def custom?(input) #: bool
          !valid?(input)
        end

        # Resolves a built-in theme name or custom file path to a color mapping.
        # If theme matches a built-in theme name, returns that theme's mapping.
        # Otherwise, attempts to load theme as a file path (raises on error).
        # Mirrors TypeScript resolveTheme.
        #
        # @rbs theme: String
        def resolve(theme) #: Hash[String, String?]
          @themes[theme] || load_from_file(theme)
        end

        # Adds a built-in theme. Called at file load time for each built-in theme.
        #
        # @rbs name: String
        # @rbs mapping: Hash[String, String?]
        def register(name, mapping) #: void
          @themes[name] = mapping
        end

        private

        # Reads and parses a JSON theme file.
        # Validates that all required ColorScheme keys are present.
        # All errors are wrapped with a descriptive message.
        #
        # @rbs path: String
        def load_from_file(path) #: Hash[String, String?]
          content = File.read(File.expand_path(path))
          custom_theme = JSON.parse(content)

          missing = required_keys - custom_theme.keys
          raise "Custom theme is missing required properties: #{missing.join(', ')}" if missing.any?

          custom_theme
        rescue StandardError => e
          raise "Failed to load custom theme from #{path}: #{e.message}"
        end

        # Returns the required ColorScheme keys derived from the onedark reference theme.
        def required_keys #: Array[String]
          @themes[DEFAULT_THEME]&.keys || []
        end
      end
    end
  end
end

# Built-in theme registrations — loaded at require time.
# JSON files live in herb-highlighter/themes/ (3 directories up from this file).
THEMES_DIR = File.expand_path("../../../themes", __dir__) #: String

Herb::Highlighter::Themes.register(
  "onedark",
  JSON.parse(File.read(File.join(THEMES_DIR, "onedark.json")))
)
