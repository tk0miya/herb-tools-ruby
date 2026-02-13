# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-equals-spacing.ts
# Documentation: https://herb-tools.dev/linter/rules/html-attribute-equals-spacing

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow whitespace before or after the equals sign (=) for attribute values in HTML. Attributes must
        #   follow the canonical format (name="value") with no spaces between the attribute name, the equals sign, or
        #   the opening quote.
        #
        # Good:
        #   <div class="container"></div>
        #   <img src="/logo.png" alt="Logo">
        #   <input type="text" value="<%= @value %>" autocomplete="off">
        #
        # Bad:
        #   <div class ="container"></div>
        #
        #   <img src= "/logo.png" alt="Logo">
        #
        #   <input type = "text" autocomplete="off">
        #
        class AttributeEqualsSpacing < VisitorRule
          def self.rule_name = "html-attribute-equals-spacing" #: String
          def self.description = "Disallow spaces around `=` in attribute assignments" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            check_spacing(node) if node.equals && node.name && node.value
            super
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            equals = copy_token(node.equals, content: "=")
            new_node = copy_html_attribute_node(node, equals:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def check_spacing(node) #: void
            if node.equals.value.start_with?(" ")
              add_offense_with_autofix(
                message: "Remove whitespace before `=` in HTML attribute",
                location: node.equals.location,
                node:
              )
            end

            return unless node.equals.value.end_with?(" ")

            add_offense_with_autofix(
              message: "Remove whitespace after `=` in HTML attribute",
              location: node.equals.location,
              node:
            )
          end
        end
      end
    end
  end
end
