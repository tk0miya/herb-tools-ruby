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
          def autofix(node, parse_result) # rubocop:disable Metrics/MethodLength
            value = node.value
            return false if value.nil? || value.quoted

            # Create a simple range and location for the quote tokens
            # The printer will use these tokens' values but doesn't strictly need accurate positions
            start_pos = value.location.start
            quote_range = Herb::Range.new(start_pos, start_pos)
            quote_location = Herb::Location.new(start_pos, start_pos)

            # Create quote tokens for the attribute value
            open_quote = Herb::Token.new(
              '"',
              quote_range,
              quote_location,
              "quote"
            )
            close_quote = Herb::Token.new(
              '"',
              quote_range,
              quote_location,
              "quote"
            )

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
