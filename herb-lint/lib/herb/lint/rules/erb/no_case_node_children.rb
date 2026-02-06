# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-case-node-children.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-case-node-children

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that disallows direct children inside case ERB blocks.
        #
        # Content should be inside when/else branches, not directly in the case block.
        #
        # Good:
        #   <% case value %>
        #   <% when :a %>
        #     <p>A</p>
        #   <% else %>
        #     <p>Default</p>
        #   <% end %>
        #
        # Bad:
        #   <% case value %>
        #     <p>Direct content</p>
        #   <% when :a %>
        #     <p>A</p>
        #   <% end %>
        class NoCaseNodeChildren < VisitorRule
          def self.rule_name #: String
            "erb-no-case-node-children"
          end

          def self.description #: String
            "Disallow direct children inside case ERB blocks"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def visit_erb_case_node(node)
            if non_whitespace_children?(node)
              add_offense(
                message: "Direct content inside case block should be moved to when/else branches",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::ERBCaseNode
          def non_whitespace_children?(node) #: bool
            return false if node.children.empty?

            # Check if any child is not just whitespace text
            node.children.any? do |child|
              # If it's not an HTMLTextNode, it's non-whitespace content
              next true unless child.is_a?(Herb::AST::HTMLTextNode)

              # If it's an HTMLTextNode, check if it has non-whitespace content
              content = child.content
              !content.nil? && !content.strip.empty?
            end
          end
        end
      end
    end
  end
end
