# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that enforces ERB comment syntax.
      #
      # ERB comments should use the dedicated comment tag syntax (`<%#`)
      # rather than a statement tag with a Ruby line comment (`<% #`).
      #
      # Good:
      #   <%# This is a comment %>
      #
      # Bad:
      #   <% # This is a comment %>
      class ErbCommentSyntax < VisitorRule
        def self.rule_name #: String
          "erb-comment-syntax"
        end

        def self.description #: String
          "Enforce ERB comment style"
        end

        def self.default_severity #: String
          "warning"
        end

        def self.safe_autocorrectable? #: bool
          true
        end

        # @rbs override
        def visit_erb_content_node(node)
          if statement_tag?(node) && comment_content?(node)
            add_offense_with_autofix(
              message: "Use ERB comment tag `<%#` instead of `<% #`",
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

          # Remove leading whitespace and # from content
          new_content_value = node.content.value.sub(/\A\s*#/, "")
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
          node.content.value.match?(/\A\s*#/)
        end
      end
    end
  end
end
