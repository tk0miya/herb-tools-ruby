# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that requires a type attribute on button elements.
        #
        # Without an explicit type, buttons default to type="submit",
        # which can cause unexpected form submissions. Requiring an
        # explicit type makes the intent clear.
        #
        # Good:
        #   <button type="button">Click</button>
        #   <button type="submit">Submit</button>
        #   <button type="reset">Reset</button>
        #
        # Bad:
        #   <button>Click</button>
        class ButtonType < VisitorRule
          def self.rule_name #: String
            "html/button-type"
          end

          def self.description #: String
            "Require type attribute on button elements"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            if button_element?(node) && !type_attribute?(node)
              add_offense(
                message: "Missing type attribute on button element (defaults to 'submit')",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def button_element?(node) #: bool
            node.tag_name&.value&.downcase == "button"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def type_attribute?(node) #: bool
            return false unless node.open_tag

            node.open_tag.children.any? do |child|
              attribute_node?(child) && attribute_name(child) == "type"
            end
          end

          # @rbs node: untyped
          def attribute_node?(node) #: bool
            node.is_a?(Herb::AST::HTMLAttributeNode)
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          def attribute_name(node) #: String?
            node.name.children.first&.content&.downcase
          end
        end
      end
    end
  end
end
