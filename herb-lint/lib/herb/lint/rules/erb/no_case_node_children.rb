# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-case-node-children.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-case-node-children

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Disallow placing content or expressions directly between the opening
        #   `<% case %>` and the first `<% when %>` or `<% in %>` clause in an
        #   HTML+ERB template.
        #
        #   In Ruby and ERB, `case` expressions are intended to branch execution.
        #   Any content placed between the `case` and its `when`/`in` clauses is
        #   not executed as part of the branching logic, and may lead to confusion,
        #   orphaned output, or silent bugs.
        #
        # Good:
        #   <% case variable %>
        #   <% when "a" %>
        #     A
        #   <% when "b" %>
        #     B
        #   <% else %>
        #     C
        #   <% end %>
        #
        # Bad:
        #   <% case variable %>
        #     This content is outside of any when/in/else block!
        #   <% when "a" %>
        #     A
        #   <% when "b" %>
        #     B
        #   <% else %>
        #     C
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
            check_case_node_children(node)
            super
          end

          # @rbs override
          def visit_erb_case_match_node(node)
            check_case_node_children(node)
            super
          end

          private

          # @rbs node: (Herb::AST::ERBCaseNode | Herb::AST::ERBCaseMatchNode)
          def check_case_node_children(node) #: void
            return if node.children.empty?

            # Check if any child contains disallowed content
            node.children.each do |child|
              next if allowed_content?(child)

              add_offense(
                message: "Content exists outside of any rendered when/in/else branches",
                location: node.location
              )
              break
            end
          end

          # @rbs node: Herb::AST::Node
          def allowed_content?(node) #: bool
            case node
            when Herb::AST::WhitespaceNode, Herb::AST::HTMLCommentNode
              # Whitespace and comment nodes are always allowed
              true
            when Herb::AST::HTMLTextNode
              # HTML text nodes are allowed if they contain only whitespace
              content = node.content
              content.nil? || content.match?(/\A\s*\z/)
            when Herb::AST::LiteralNode
              # Literal nodes are allowed if they contain only whitespace
              node.content.match?(/\A\s*\z/)
            else
              # All other content is disallowed
              false
            end
          end
        end
      end
    end
  end
end
