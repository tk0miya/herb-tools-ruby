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
      #
      # @see https://herb-tools.dev/linter/rules/erb-comment-syntax Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-comment-syntax.ts Source
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

        # @rbs override
        def visit_erb_content_node(node)
          if statement_tag?(node) && comment_content?(node)
            add_offense(
              message: "Use ERB comment tag `<%#` instead of `<% #`",
              location: node.tag_opening.location
            )
          end
          super
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
