# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-level-must-be-valid.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-level-must-be-valid

module Herb
  module Lint
    module Rules
      # Rule that validates aria-level attribute values.
      #
      # The aria-level attribute must have a valid integer value between 1 and 6
      # when used on elements with role="heading".
      #
      # Good:
      #   <div role="heading" aria-level="1">
      #   <div role="heading" aria-level="6">
      #
      # Bad:
      #   <div role="heading" aria-level="0">
      #   <div role="heading" aria-level="7">
      #   <div role="heading" aria-level="abc">
      class HtmlAriaLevelMustBeValid < VisitorRule
        VALID_LEVELS = (1..6) #: Range[Integer]

        def self.rule_name #: String
          "html-aria-level-must-be-valid"
        end

        def self.description #: String
          "aria-level attribute must have a valid integer value (1-6)"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_html_attribute_node(node)
          if aria_level_attribute?(node)
            value = attribute_value(node)
            unless valid_aria_level?(value)
              add_offense(
                message: "aria-level must be a valid integer between 1 and 6, got '#{value}'",
                location: node.location
              )
            end
          end
          super
        end

        private

        # @rbs node: Herb::AST::HTMLAttributeNode
        def aria_level_attribute?(node) #: bool
          attribute_name(node)&.downcase == "aria-level"
        end

        # @rbs value: String?
        def valid_aria_level?(value) #: bool
          return false if value.nil? || value.empty?

          integer_value = Integer(value, exception: false)
          return false if integer_value.nil?

          VALID_LEVELS.cover?(integer_value)
        end
      end
    end
  end
end
