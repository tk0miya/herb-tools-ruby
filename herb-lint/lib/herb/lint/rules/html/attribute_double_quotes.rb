# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-double-quotes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-attribute-double-quotes

module Herb
  module Lint
    module Rules
      module Html
        # Rule that requires attribute values to be quoted.
        #
        # Unquoted attribute values are valid HTML5, but quoting them improves
        # readability and prevents issues with special characters.
        #
        # Good:
        #   <div class="container">
        #   <input type='text'>
        #   <input disabled>
        #
        # Bad:
        #   <div class=container>
        #   <input type=text>
        class AttributeDoubleQuotes < VisitorRule
          def self.rule_name #: String
            "html-attribute-double-quotes"
          end

          def self.description #: String
            "Attribute values should be quoted"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.autocorrectable? #: bool
            true
          end

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

          # @rbs override
          def autofix(node, parse_result)
            value = node.value
            return false if value.nil? || value.quoted

            # Create quote tokens for the attribute value
            start_pos = value.location.start
            open_quote = build_quote_token(start_pos)
            close_quote = build_quote_token(start_pos)

            # Create new value node with quotes
            new_value = copy_html_attribute_value_node(
              value,
              open_quote:,
              close_quote:,
              quoted: true
            )

            # Create new attribute node with the quoted value
            new_node = copy_html_attribute_node(node, value: new_value)

            # Replace the node in the AST
            replace_node(parse_result, node, new_node)
          end

          private

          # Build a quote token at the given position.
          # The printer will use the token's value but doesn't strictly need accurate positions.
          #
          # @rbs position: Herb::Position
          def build_quote_token(position) #: Herb::Token
            quote_range = Herb::Range.new(position, position)
            quote_location = Herb::Location.new(position, position)

            Herb::Token.new(
              '"',
              quote_range,
              quote_location,
              "quote"
            )
          end

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
