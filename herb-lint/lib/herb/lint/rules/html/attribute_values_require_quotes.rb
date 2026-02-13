# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-values-require-quotes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-attribute-values-require-quotes

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Always wrap HTML attribute values in quotes, even when they are technically optional according to the
        #   HTML specification.
        #
        # Good:
        #   <div id="hello"></div>
        #
        #   <input type="text" autocomplete="off">
        #
        #   <a href="/profile">Profile</a>
        #
        # Bad:
        #   <div id=hello></div>
        #
        #   <input type=text autocomplete="off">
        #
        #   <a href=profile></a>
        #
        class AttributeValuesRequireQuotes < VisitorRule
          def self.rule_name = "html-attribute-values-require-quotes" #: String
          def self.description = "Require quotes around attribute values" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            if unquoted_value?(node)
              add_offense_with_autofix(
                message: "Attribute value should be quoted",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            value = node.value
            return false if value.nil?

            new_value = copy_html_attribute_value_node(
              value,
              open_quote: build_quote_token(value.location.start),
              close_quote: build_quote_token(value.location.start),
              quoted: true
            )
            new_node = copy_html_attribute_node(node, value: new_value)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def unquoted_value?(node) #: bool
            value = node.value
            # Boolean attributes (no value) are OK
            return false if value.nil?

            # Check if value is not quoted
            !value.quoted
          end
        end
      end
    end
  end
end
