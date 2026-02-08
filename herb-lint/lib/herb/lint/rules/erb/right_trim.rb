# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-right-trim.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-right-trim

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that detects the obscure `=%>` right-trim syntax in ERB tags.
        #
        # The `=%>` syntax is obscure and not well-supported in most ERB engines.
        # Use `-%>` instead for right-trimming whitespace after ERB tags.
        #
        # Bad:
        #   <% if condition =%>
        #     <p>Content</p>
        #   <% end =%>
        #
        # Good:
        #   <% if condition -%>
        #     <p>Content</p>
        #   <% end -%>
        class RightTrim < VisitorRule
          def self.rule_name #: String
            "erb-right-trim"
          end

          def self.description #: String
            "Use `-%>` instead of `=%>` for right-trimming"
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autofixable? #: bool
            true
          end

          # Check each ERB node for the obscure =%> syntax
          # @rbs override
          def visit_child_nodes(node)
            check_erb_node(node) if node.class.name&.start_with?("Herb::AST::ERB")
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            tag_closing = copy_token(node.tag_closing, content: "-%>")
            new_node = copy_erb_node(node, tag_closing:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: untyped
          def check_erb_node(node) #: void
            return unless node.tag_closing
            return unless node.tag_closing.value == "=%>"

            add_offense_with_autofix(
              message: "Use `-%>` instead of `=%>` for right-trimming. " \
                       "The `=%>` syntax is obscure and not well-supported in most ERB engines.",
              location: node.tag_closing.location,
              node:
            )
          end
        end
      end
    end
  end
end
