# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-level-must-be-valid.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-level-must-be-valid

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that the value of the aria-level attribute is a valid heading level: an integer between 1
        #   and 6. This attribute is used with role="heading" to indicate a heading level for non-semantic
        #   elements like <div> or <span>.
        #
        # Good:
        #   <div role="heading" aria-level="1">Main</div>
        #   <div role="heading" aria-level="6">Footnote</div>
        #
        # Bad:
        #   <div role="heading" aria-level="-1">Negative</div>
        #
        #   <div role="heading" aria-level="0">Main</div>
        #
        #   <div role="heading" aria-level="7">Too deep</div>
        #
        #   <div role="heading" aria-level="foo">Invalid</div>
        #
        class AriaLevelMustBeValid < VisitorRule
          VALID_LEVELS = (1..6) #: Range[Integer]

          def self.rule_name = "html-aria-level-must-be-valid" #: String
          def self.description = "The `aria-level` attribute must be an integer between 1 and 6" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            if aria_level_attribute?(node)
              value = attribute_value(node)
              unless valid_aria_level?(value)
                message =
                  if value.nil? || value.empty?
                    "The `aria-level` attribute must be an integer between 1 and 6, got an empty value."
                  else
                    "The `aria-level` attribute must be an integer between 1 and 6, got `#{value}`."
                  end

                add_offense(message:, location: node.location)
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

            # Ensure the value is exactly the string representation of the integer
            # This rejects values like "1.5", "1abc", etc.
            return false unless value == integer_value.to_s

            VALID_LEVELS.cover?(integer_value)
          end
        end
      end
    end
  end
end
