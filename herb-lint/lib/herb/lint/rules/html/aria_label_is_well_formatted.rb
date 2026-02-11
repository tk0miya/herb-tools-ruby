# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-label-is-well-formatted.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-label-is-well-formatted

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that the value of the aria-label attribute is formatted like natural, visual text.
        #   The text should use sentence case (capitalize the first letter), avoid line breaks,
        #   and not look like an ID or code identifier.
        #
        # Good:
        #   <button aria-label="Close dialog">X</button>
        #   <input aria-label="Search products" type="search" autocomplete="off">
        #   <button aria-label="Page 2 of 10">2</button>
        #
        # Bad:
        #   <!-- Starts with lowercase -->
        #   <button aria-label="close dialog">X</button>
        #
        #   <!-- Contains line breaks -->
        #   <button aria-label="Close
        #   dialog">X</button>
        #
        #   <!-- Looks like an ID (snake_case) -->
        #   <button aria-label="close_dialog">X</button>
        #
        #   <!-- Looks like an ID (kebab-case) -->
        #   <button aria-label="close-dialog">X</button>
        #
        #   <!-- Looks like an ID (camelCase) -->
        #   <button aria-label="closeDialog">X</button>
        #
        #   <!-- HTML entity line breaks -->
        #   <button aria-label="Close&#10;dialog">X</button>
        #
        class AriaLabelIsWellFormatted < VisitorRule
          def self.rule_name = "html-aria-label-is-well-formatted" #: String
          def self.description = "Require well-formatted aria-label values" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            attr = find_attribute(node, "aria-label")
            if attr
              value = attribute_value(attr)
              check_aria_label_value(attr, value) if value
            end
            super
          end

          private

          # @rbs attr: Herb::AST::HTMLAttributeNode
          # @rbs value: String
          def check_aria_label_value(attr, value) #: void
            if contains_line_breaks?(value)
              add_offense(
                message: "The `aria-label` attribute value text should not contain line breaks. " \
                         "Use concise, single-line descriptions.",
                location: attr.location
              )
            elsif looks_like_id?(value)
              add_offense(
                message: "The `aria-label` attribute value should not be formatted like an ID. " \
                         "Use natural, sentence-case text instead.",
                location: attr.location
              )
            elsif value.match?(/\A[a-z]/)
              add_offense(
                message: "The `aria-label` attribute value text should be formatted like visual text. " \
                         "Use sentence case (capitalize the first letter).",
                location: attr.location
              )
            end
          end

          # @rbs value: String
          def contains_line_breaks?(value) #: bool
            # Check for literal line breaks
            return true if value.match?(/[\r\n]+/)

            # Check for HTML entity line breaks: &#10;, &#13;, &#x0A;, &#x0D;
            value.match?(/&#(?:10|13|x0[AD]);/i)
          end

          # @rbs value: String
          def looks_like_id?(value) #: bool
            # Check for snake_case or kebab-case
            return true if value.include?("_") || value.include?("-")

            # Check for camelCase (starts with lowercase, contains uppercase, no spaces)
            value.match?(/^[a-z]+[A-Z]/) && !value.include?(" ")
          end
        end
      end
    end
  end
end
