# frozen_string_literal: true

require "herb"

module Herb
  module Highlight
    # Token-level ERB/HTML syntax highlighting.
    # Takes a single line of source text, tokenizes it with Herb.lex(), and returns
    # the same text with ANSI codes injected around each token.
    # Mirrors TypeScript SyntaxRenderer.
    #
    # Fallback: returns source unchanged (no ANSI codes) when:
    # - No theme was given (theme_name: nil and theme: nil)
    # - Theme name not found in registry
    # - Herb.lex(source) result has errors
    class SyntaxRenderer # rubocop:disable Metrics/ClassLength
      # Ruby keywords to highlight specially inside ERB content.
      RUBY_KEYWORDS = %w[
        if unless else elsif end def class module return yield break next
        case when then while until for in do begin rescue ensure retry
        raise super self nil true false and or not
      ].freeze #: Array[String]

      # @rbs @theme: Hash[String, String?]?

      # @rbs theme_name: String? -- looked up via Themes; nil = plain text
      # @rbs theme: Hash[String, String?]? -- pre-resolved theme (for testing; takes priority over theme_name)
      def initialize(theme_name: nil, theme: nil) #: void
        @theme =
          if theme
            theme
          elsif theme_name
            Themes.names.include?(theme_name) ? Themes.resolve(theme_name) : nil
          end
      end

      # Applies syntax highlighting to a single line of ERB/HTML source.
      # Returns source unchanged if no theme is set or if lexing fails.
      #
      # @rbs source: String
      def render(source) #: String
        return source unless @theme

        result = Herb.lex(source)
        return source if result.failed? || result.errors.any?

        state = initial_state
        output = +""

        result.value.each do |token|
          next if token.type == "TOKEN_EOF"

          color = contextual_color(state, token.type)
          update_state(state, token.type, token.value)
          output << render_token(token.type, token.value, color)
        end

        output
      end

      private

      # Returns the initial parser state hash.
      def initial_state #: Hash[Symbol, untyped]
        {
          in_tag: false,
          in_quotes: false,
          quote_char: "",
          tag_name: "",
          is_closing_tag: false,
          expecting_attribute_name: false,
          expecting_attribute_value: false,
          in_comment: false
        }
      end

      # Selects the appropriate theme color for the current token given the current state.
      # Called BEFORE state is updated so that attribute name/value detection works correctly.
      #
      # @rbs state: Hash[Symbol, untyped]
      # @rbs token_type: String
      def contextual_color(state, token_type) #: String?
        # Comment content: tokens inside <!-- --> (excluding delimiters and ERB tokens)
        # inherit the comment color.
        if state[:in_comment] && !comment_delimiter?(token_type) && !erb_token?(token_type)
          return @theme["TOKEN_HTML_COMMENT_START"]
        end

        case token_type
        when "TOKEN_HTML_TAG_START_CLOSE"
          @theme["TOKEN_HTML_TAG_START"]
        when "TOKEN_HTML_TAG_SELF_CLOSE"
          @theme["TOKEN_HTML_TAG_END"]
        when "TOKEN_IDENTIFIER"
          identifier_color(state)
        when "TOKEN_QUOTE"
          state[:in_tag] ? @theme["TOKEN_QUOTE"] : nil
        else
          @theme[token_type]
        end
      end

      # @rbs token_type: String
      def comment_delimiter?(token_type) #: bool
        %w[TOKEN_HTML_COMMENT_START TOKEN_HTML_COMMENT_END].include?(token_type)
      end

      # @rbs token_type: String
      def erb_token?(token_type) #: bool
        %w[TOKEN_ERB_START TOKEN_ERB_CONTENT TOKEN_ERB_END].include?(token_type)
      end

      # Determines the color for an IDENTIFIER token based on current state.
      # Uses pre-update state: tag_name.empty? detects the element name identifier.
      #
      # @rbs state: Hash[Symbol, untyped]
      def identifier_color(state) #: String?
        return nil unless state[:in_tag]

        if state[:tag_name].empty?
          # First identifier in a tag is the element name
          @theme["TOKEN_HTML_TAG_START"]
        elsif state[:expecting_attribute_name]
          @theme["TOKEN_HTML_ATTRIBUTE_NAME"]
        elsif state[:in_quotes]
          @theme["TOKEN_HTML_ATTRIBUTE_VALUE"]
        end
      end

      # Updates the state machine based on the current token.
      # Called after color is determined for the current token.
      #
      # @rbs state: Hash[Symbol, untyped]
      # @rbs token_type: String
      # @rbs token_text: String
      def update_state(state, token_type, token_text) #: void # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        case token_type
        when "TOKEN_HTML_TAG_START"
          state[:in_tag] = true
          state[:is_closing_tag] = false
          state[:expecting_attribute_name] = false
          state[:expecting_attribute_value] = false
        when "TOKEN_HTML_TAG_START_CLOSE"
          state[:in_tag] = true
          state[:is_closing_tag] = true
          state[:expecting_attribute_name] = false
          state[:expecting_attribute_value] = false
        when "TOKEN_HTML_TAG_END", "TOKEN_HTML_TAG_SELF_CLOSE"
          state[:in_tag] = false
          state[:tag_name] = ""
          state[:is_closing_tag] = false
          state[:expecting_attribute_name] = false
          state[:expecting_attribute_value] = false
        when "TOKEN_IDENTIFIER"
          if state[:in_tag]
            if state[:tag_name].empty?
              state[:tag_name] = token_text
              state[:expecting_attribute_name] = !state[:is_closing_tag]
            elsif state[:expecting_attribute_name]
              state[:expecting_attribute_name] = false
              state[:expecting_attribute_value] = true
            end
          end
        when "TOKEN_EQUALS"
          state[:expecting_attribute_value] = true if state[:in_tag]
        when "TOKEN_QUOTE"
          if state[:in_tag]
            if !state[:in_quotes]
              state[:in_quotes] = true
              state[:quote_char] = token_text
            elsif state[:quote_char] == token_text
              state[:in_quotes] = false
              state[:quote_char] = ""
              state[:expecting_attribute_name] = true
              state[:expecting_attribute_value] = false
            end
          end
        when "TOKEN_WHITESPACE"
          if state[:in_tag] && !state[:in_quotes] && !state[:tag_name].empty?
            state[:expecting_attribute_name] = true
            state[:expecting_attribute_value] = false
          end
        when "TOKEN_HTML_COMMENT_START"
          state[:in_comment] = true
        when "TOKEN_HTML_COMMENT_END"
          state[:in_comment] = false
        end
      end

      # Renders a single token with the given color, with special handling for ERB content.
      #
      # @rbs token_type: String
      # @rbs token_text: String
      # @rbs color: String?
      def render_token(token_type, token_text, color) #: String
        if token_type == "TOKEN_ERB_CONTENT"
          highlight_ruby_code(token_text)
        elsif color
          Color.colorize(token_text, color)
        else
          token_text
        end
      end

      # Colorizes Ruby code inside ERB tags.
      # Splits the code into tokens and colorizes Ruby keywords and identifiers.
      #
      # @rbs code: String
      def highlight_ruby_code(code) #: String
        parts = code.split(/(\s+|[^\w\s]+)/)
        parts.map do |part|
          if RUBY_KEYWORDS.include?(part)
            color = @theme["RUBY_KEYWORD"]
            color ? Color.colorize(part, color) : part
          elsif part.match?(/\A\w/)
            color = @theme["TOKEN_ERB_CONTENT"] || @theme["TOKEN_IDENTIFIER"]
            color ? Color.colorize(part, color) : part
          else
            part
          end
        end.join
      end
    end
  end
end
