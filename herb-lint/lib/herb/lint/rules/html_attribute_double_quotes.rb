# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      #
      # @see https://herb-tools.dev/linter/rules/html-attribute-double-quotes Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-double-quotes.ts Source
      class HtmlAttributeDoubleQuotes < VisitorRule
        def self.rule_name #: String
          "html-attribute-double-quotes"
        end

        def self.description #: String
          "Attribute values should be quoted"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_attribute_node(node)
          if unquoted_value?(node)
            add_offense(
              message: "Attribute value should be quoted",
              location: node.location
            )
          end
          super
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
