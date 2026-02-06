# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-comment-syntax.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-comment-syntax

module Herb
  module Lint
    module Rules
      module Erb
        # Enforces ERB comment syntax.
        #
        # Detects when developers use <% # (which can cause parsing issues)
        # instead of the correct <%# syntax.
        #
        # Good:
        #   <%# This is a comment %>
        #
        # Bad:
        #   <% # This is a comment %>
        class CommentSyntax < VisitorRule
          def self.rule_name #: String
            "erb-comment-syntax"
          end

          def self.description #: String
            "Enforce ERB comment style"
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autocorrectable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            if statement_tag?(node) && comment_content?(node)
              message = build_message(node)
              add_offense_with_autofix(
                message:,
                location: node.tag_opening.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            # Create new opening tag token with <%# instead of <%
            tag_opening = copy_token(node.tag_opening, content: "<%#")

            # Remove leading spaces and # from content
            new_content_value = node.content.value.sub(/\A +#/, "")
            content = copy_token(node.content, content: new_content_value)

            # Create new ERBContentNode with modified tokens
            new_node = copy_erb_content_node(node, tag_opening:, content:)

            # Replace the node in the AST
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def statement_tag?(node) #: bool
            node.tag_opening.value == "<%"
          end

          # @rbs node: Herb::AST::ERBContentNode
          def comment_content?(node) #: bool
            node.content.value.match?(/\A +#/)
          end

          # @rbs node: Herb::AST::ERBContentNode
          def build_message(node) #: String
            opening_tag = node.tag_opening.value
            content = node.content.value

            if content.include?("herb:disable")
              "Use `<%#` instead of `#{opening_tag} #` for `herb:disable` directives."
            else
              "Use `<%#` instead of `#{opening_tag} #`. Ruby comments may cause parsing issues."
            end
          end
        end
      end
    end
  end
end
