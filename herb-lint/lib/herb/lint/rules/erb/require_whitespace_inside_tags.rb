# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-whitespace-inside-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-require-whitespace-inside-tags

module Herb
  module Lint
    module Rules
      module Erb
        # Enforces whitespace requirements inside ERB template tags for improved readability.
        #
        # Requires a single space before and after Ruby code inside ERB tags.
        #
        # Good:
        #   <%= user.name %>
        #   <% if admin %>
        #     Hello, admin.
        #   <% end %>
        #
        # Bad:
        #   <%=user.name %>
        #   <%if admin %>
        #     Hello, admin.
        #   <% end%>
        class RequireWhitespaceInsideTags < VisitorRule
          def self.rule_name #: String
            "erb-require-whitespace-inside-tags"
          end

          def self.description #: String
            "Require whitespace inside ERB tag delimiters"
          end

          def self.default_severity #: String
            "error"
          end

          def self.autocorrectable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            content_value = node.content&.value

            if missing_whitespace?(node, content_value)
              add_offense_with_autofix(
                message: "Add whitespace inside ERB tag delimiters",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            content_value = node.content&.value
            return false if content_value.nil?

            content_value = " #{content_value}" unless content_value.start_with?(" ", "\t", "\n")
            content_value = "#{content_value} " unless content_value.end_with?(" ", "\t", "\n")

            content = copy_token(node.content, content: content_value)
            new_node = copy_erb_content_node(node, content:)
            replace_node(parse_result, node, new_node)
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
end
