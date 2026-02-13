# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-double-quotes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-attribute-double-quotes

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Prefer using double quotes (") around HTML attribute values instead of single quotes (').
        #
        #   Exception:
        #   Single quotes are allowed when the attribute value contains double quotes, as this avoids the need for
        #   escaping.
        #
        # Good:
        #   <input type="text" autocomplete="off">
        #
        #   <a href="/profile">Profile</a>
        #
        #   <div data-action="click->dropdown#toggle"></div>
        #
        #   <!-- Exception: Single quotes allowed when value contains double quotes -->
        #   <div id='"hello"' title='Say "Hello" to the world'></div>
        #
        # Bad:
        #   <input type='text' autocomplete="off">
        #
        #   <a href='/profile'>Profile</a>
        #
        #   <div data-action='click->dropdown#toggle'></div>
        #
        class AttributeDoubleQuotes < VisitorRule
          def self.rule_name = "html-attribute-double-quotes" #: String
          def self.description = "Prefer double quotes for HTML attribute values" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            if single_quoted_value?(node)
              attr_name = node.name.children.first&.content
              add_offense_with_autofix(
                message: "Attribute `#{attr_name}` uses single quotes. Prefer double quotes for HTML attribute values",
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

            # Replace single quotes with double quotes
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
          def single_quoted_value?(node) #: bool
            value = node.value
            # Boolean attributes (no value) are OK
            return false if value.nil?

            # Only check quoted values
            return false unless value.quoted

            # Check if using single quotes
            return false unless value.open_quote&.value == "'"

            # Exception: Allow single quotes when value contains double quotes
            # This avoids the need for escaping
            !value_contains_double_quotes?(value)
          end

          # @rbs value: Herb::AST::HTMLAttributeValueNode
          def value_contains_double_quotes?(value) #: bool
            # Check all children for literal nodes containing double quotes
            value.children.any? do |child|
              child.is_a?(Herb::AST::LiteralNode) && child.content.include?('"')
            end
          end
        end
      end
    end
  end
end
