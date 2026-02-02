# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # String manipulation utilities for lint rules
      module StringHelpers
        # Checks if parentheses in a string are balanced
        # Returns false if there are more closing parens than opening at any point
        #
        # @rbs content: String -- the string to check
        # @rbs return: bool
        def balanced_parentheses?(content)
          depth = 0

          content.each_char do |char|
            depth += 1 if char == "("
            depth -= 1 if char == ")"
            return false if depth.negative?
          end

          depth.zero?
        end

        # Splits a string by commas at the top level only
        # Respects nested parentheses, brackets, braces, and strings
        #
        # @example
        #   split_by_top_level_comma("a, b, c") #=> ["a", " b", " c"]
        #   split_by_top_level_comma("a, (b, c), d") #=> ["a", " (b, c)", " d"]
        #   split_by_top_level_comma('a, "b, c", d') #=> ["a", ' "b, c"', " d"]
        #
        # @rbs str: String -- the string to split
        # @rbs return: Array[String]
        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def split_by_top_level_comma(str)
          result = []
          current = ""
          paren_depth = 0
          bracket_depth = 0
          brace_depth = 0
          in_string = false
          string_char = nil

          str.chars.each_with_index do |char, i|
            previous_char = i.positive? ? str[i - 1] : ""

            if ['"', "'"].include?(char) && previous_char != "\\"
              if !in_string
                in_string = true
                string_char = char
              elsif char == string_char
                in_string = false
              end
            end

            unless in_string
              paren_depth += 1 if char == "("
              paren_depth -= 1 if char == ")"
              bracket_depth += 1 if char == "["
              bracket_depth -= 1 if char == "]"
              brace_depth += 1 if char == "{"
              brace_depth -= 1 if char == "}"

              if char == "," && paren_depth.zero? && bracket_depth.zero? && brace_depth.zero?
                result << current
                current = ""
                next
              end
            end

            current += char
          end

          result << current unless current.empty?

          result
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      end
    end
  end
end
