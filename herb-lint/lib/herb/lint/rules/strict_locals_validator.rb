# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-strict-locals-comment-syntax.ts

module Herb
  module Lint
    module Rules
      # Validates ERB strict locals comment syntax.
      #
      # This class is responsible for parsing and validating the content of ERB
      # strict locals magic comments. It is independent of lint rule classes and
      # focuses solely on string validation.
      #
      # @example Check if a string is a locals declaration
      #   StrictLocalsValidator.locals_declaration?("locals: (name:)")  #=> true
      #   StrictLocalsValidator.locals_declaration?("TODO: fix this")   #=> false
      #
      # @example Validate strict locals syntax
      #   StrictLocalsValidator.validate("locals: (name:)")       #=> nil (valid)
      #   StrictLocalsValidator.validate("locals: (name:, age:)") #=> nil (valid)
      #   StrictLocalsValidator.validate("locals(name:)")         #=> "Use `locals:` ..."
      class StrictLocalsValidator
        STRICT_LOCALS_PATTERN = /\Alocals:\s+\([^)]*\)\s*\z/

        # Check if a comment string looks like a strict locals declaration
        # (whether valid or invalid syntax).
        #
        # @rbs comment: String
        def self.locals_declaration?(comment) #: bool
          content = comment.strip
          content.match?(/\Alocals?\b/) && content.match?(/[(:)]/)
        end

        # Validate a strict locals comment string.
        #
        # Assumes the input is a locals declaration (use .locals_declaration? to check first).
        # Returns nil if the syntax is valid, or an error message String if invalid.
        #
        # @rbs comment: String
        def self.validate(comment) #: String?
          new(comment.strip).validate
        end

        # @rbs comment: String
        def initialize(comment) #: void
          @comment = comment
        end

        # @rbs @comment: String

        def validate #: String?
          return unbalanced_parentheses_message unless balanced_parentheses?
          return detect_format_error unless valid_format?

          validate_parameters
        end

        private

        # --- Format validation ---

        def valid_format? #: bool
          STRICT_LOCALS_PATTERN.match?(@comment)
        end

        def balanced_parentheses? #: bool
          depth = 0

          @comment.each_char do |char|
            depth += 1 if char == "("
            depth -= 1 if char == ")"
            return false if depth.negative?
          end

          depth.zero?
        end

        def detect_format_error #: String
          case @comment
          when /\Alocals?\(/
            "Use `locals:` with a colon, not `locals()`. Correct format: `<%# locals: (...) %>`."
          when /\Alocal:/
            "Use `locals:` (plural), not `local:`."
          when /\Alocals\s+\(/
            "Use `locals:` with a colon before the parentheses, not `locals (`."
          when /\Alocals:\(/
            "Missing space after `locals:`. " \
            "Rails Strict Locals require a space after the colon: `<%# locals: (...) %>`."
          when /\Alocals:\s*[^(]/
            "Wrap parameters in parentheses: `locals: (name:)` or `locals: (name: default)`."
          when /\Alocals:\s*\z/
            "Add parameters after `locals:`. Use `locals: (name:)` or `locals: ()` for no locals."
          else
            "Invalid `locals:` syntax. Use format: `locals: (name:, option: default)`."
          end
        end

        # --- Parameter validation ---

        def validate_parameters #: String?
          match = @comment.match(/\A\s*locals:\s*\(([\s\S]*)\)\s*\z/)
          return nil unless match

          inner = match[1].strip
          return nil if inner.empty?

          validate_comma_usage(inner) || validate_each_parameter(inner)
        end

        # @rbs inner: String
        def validate_each_parameter(inner) #: String?
          params = TopLevelCommaSplitter.split(inner)

          params.each do |param|
            error = validate_parameter(param.strip)
            return error if error
          end

          nil
        end

        # @rbs param: String
        def validate_parameter(param) #: String?
          return nil if param.empty?

          validate_block_argument(param) ||
            validate_splat_argument(param) ||
            validate_double_splat_argument(param) ||
            (param.start_with?("**") ? nil : validate_keyword_argument(param))
        end

        # @rbs param: String
        def validate_block_argument(param) #: String?
          return nil unless param.start_with?("&")

          "Block argument `#{param}` is not allowed. Strict locals only support keyword arguments."
        end

        # @rbs param: String
        def validate_splat_argument(param) #: String?
          return nil unless param.start_with?("*") && !param.start_with?("**")

          "Splat argument `#{param}` is not allowed. Strict locals only support keyword arguments."
        end

        # @rbs param: String
        def validate_double_splat_argument(param) #: String?
          return nil unless param.start_with?("**")
          return nil if param.match?(/\A\*\*\w+\z/)

          "Invalid double-splat syntax `#{param}`. Use `**name` format (e.g., `**attributes`)."
        end

        # @rbs param: String
        def validate_keyword_argument(param) #: String?
          return nil if param.match?(/\A\w+:\s*/)

          if param.match?(/\A\w+\z/)
            "Positional argument `#{param}` is not allowed. Use keyword argument format: `#{param}:`."
          else
            "Invalid parameter `#{param}`. Use keyword argument format: `name:` or `name: default`."
          end
        end

        # @rbs inner: String
        def validate_comma_usage(inner) #: String?
          return unless inner.start_with?(",") || inner.end_with?(",") || inner.include?(",,")

          "Unexpected comma in `locals:` parameters."
        end

        def unbalanced_parentheses_message #: String
          "Unbalanced parentheses in `locals:` comment. " \
            "Ensure all opening parentheses have matching closing parentheses."
        end

        # Splits a string by commas at the top level only.
        # Respects nested parentheses, brackets, braces, and strings.
        class TopLevelCommaSplitter
          QUOTE_CHARS = ['"', "'"].freeze #: Array[String]

          # @rbs str: String
          def self.split(str) #: Array[String]
            new(str).split
          end

          # @rbs str: String
          def initialize(str) #: void
            @chars = str.chars
            @result = [] #: Array[String]
            @current = +""
            @paren_depth = 0
            @bracket_depth = 0
            @brace_depth = 0
            @in_string = false
            @string_char = ""
          end

          # @rbs @chars: Array[String]
          # @rbs @result: Array[String]
          # @rbs @current: String
          # @rbs @paren_depth: Integer
          # @rbs @bracket_depth: Integer
          # @rbs @brace_depth: Integer
          # @rbs @in_string: bool
          # @rbs @string_char: String

          def split #: Array[String]
            @chars.each_with_index do |char, i|
              update_string_state(char, i)

              next if !@in_string && structural_comma?(char)

              @current << char
            end

            @result << @current unless @current.empty?
            @result
          end

          private

          # @rbs char: String
          # @rbs index: Integer
          def update_string_state(char, index) #: void
            return unless QUOTE_CHARS.include?(char)

            previous_char = index.positive? ? @chars[index - 1] : ""
            return if previous_char == "\\"

            if !@in_string
              @in_string = true
              @string_char = char
            elsif char == @string_char
              @in_string = false
            end
          end

          # @rbs char: String
          def structural_comma?(char) #: bool
            update_depth(char)

            if char == "," && @paren_depth.zero? && @bracket_depth.zero? && @brace_depth.zero?
              @result << @current
              @current = +""
              return true
            end

            false
          end

          # @rbs char: String
          def update_depth(char) #: void
            case char
            when "(" then @paren_depth += 1
            when ")" then @paren_depth -= 1
            when "[" then @bracket_depth += 1
            when "]" then @bracket_depth -= 1
            when "{" then @brace_depth += 1
            when "}" then @brace_depth -= 1
            end
          end
        end
      end
    end
  end
end
