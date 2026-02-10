# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-attribute-equals-spacing.ts
# Documentation: https://herb-tools.dev/linter/rules/html-attribute-equals-spacing

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows spaces around `=` in attribute assignments.
        #
        # Spaces around the equals sign in HTML attributes are valid but
        # unconventional. Removing them improves readability and consistency.
        #
        # Good:
        #   <div class="foo">
        #
        # Bad:
        #   <div class = "foo">
        #   <div class ="foo">
        #   <div class= "foo">
        class AttributeEqualsSpacing < VisitorRule
          def self.rule_name #: String
            "html-attribute-equals-spacing"
          end

          def self.description #: String
            "Disallow spaces around `=` in attribute assignments"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            true
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # @rbs override
          def visit_html_attribute_node(node)
            check_spacing(node) if node.equals
            super
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            # Remove spaces from equals token value
            equals = copy_token(node.equals, content: node.equals.value.gsub(/[\s\t]+/, ""))
            new_node = copy_html_attribute_node(node, equals:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def check_spacing(node) #: void
            message = spacing_message(node)
            add_offense_with_autofix(message:, location: node.location, node:) if message
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          def spacing_message(node) #: String?
            before = space_before_equals?(node)
            after = space_after_equals?(node)

            if before && after
              "Unexpected spaces around `=` in attribute assignment"
            elsif before
              "Unexpected space before `=` in attribute assignment"
            elsif after
              "Unexpected space after `=` in attribute assignment"
            end
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          def space_before_equals?(node) #: bool
            node.equals.value.start_with?(" ", "\t")
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          def space_after_equals?(node) #: bool
            return false unless node.value

            node.equals.value.end_with?(" ", "\t")
          end
        end
      end
    end
  end
end
