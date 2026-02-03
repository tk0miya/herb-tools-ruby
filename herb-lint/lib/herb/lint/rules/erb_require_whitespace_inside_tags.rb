# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that requires whitespace between ERB tag delimiters and content.
      #
      # ERB tags should have whitespace separating the opening/closing delimiters
      # from the tag content for readability.
      #
      # Good:
      #   <% value %>
      #   <%= value %>
      #
      # Bad:
      #   <%value%>
      #   <%=value%>
      #
      # @see https://herb-tools.dev/linter/rules/erb-require-whitespace-inside-tags Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-whitespace-inside-tags.ts Source
      class ErbRequireWhitespaceInsideTags < VisitorRule
        def self.rule_name #: String
          "erb-require-whitespace-inside-tags"
        end

        def self.description #: String
          "Require whitespace inside ERB tag delimiters"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_content_node(node)
          content_value = node.content&.value

          if missing_whitespace?(node, content_value)
            add_offense(
              message: "Add whitespace inside ERB tag delimiters",
              location: node.location
            )
          end
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        # @rbs content_value: String?
        def missing_whitespace?(node, content_value) #: bool
          return false if content_value.nil? || content_value.strip.empty?
          return false if comment_tag?(node)

          !content_value.start_with?(" ", "\t", "\n") ||
            !content_value.end_with?(" ", "\t", "\n")
        end

        # @rbs node: Herb::AST::ERBContentNode
        def comment_tag?(node) #: bool
          node.tag_opening.value == "<%#"
        end
      end
    end
  end
end
