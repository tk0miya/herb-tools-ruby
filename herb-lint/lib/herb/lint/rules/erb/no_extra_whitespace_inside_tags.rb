# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-extra-whitespace-inside-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-extra-whitespace-inside-tags

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   This rule disallows **multiple consecutive spaces** immediately inside ERB tags (`<%`, `<%=`) or before the
        #   closing delimiter (`%>`). It ensures that ERB code is consistently and cleanly formatted, with exactly one
        #   space after the opening tag and one space before the closing tag (when appropriate).
        #
        # Good:
        #   <%= output %>
        #
        #   <% if condition %>
        #     True
        #   <% end %>
        #
        # Bad:
        #   <%=  output %>
        #
        #   <%= output  %>
        #
        #   <%  if condition  %>
        #     True
        #   <% end %>
        #
        class NoExtraWhitespaceInsideTags < VisitorRule
          def self.rule_name #: String
            "erb-no-extra-whitespace-inside-tags"
          end

          def self.description #: String
            "Disallow extra whitespace inside ERB tag delimiters"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            if extra_whitespace?(node)
              add_offense_with_autofix(
                message: "Remove extra whitespace inside ERB tag",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            new_content_value = node.content.value.gsub(/\A\s{2,}/, " ").gsub(/\s{2,}\z/, " ")
            content = copy_token(node.content, content: new_content_value)
            new_node = copy_erb_content_node(node, content:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def extra_whitespace?(node) #: bool
            content_value = node.content&.value
            return false if content_value.nil? || content_value.strip.empty?

            # Check for 2+ spaces at the beginning or end
            leading_extra_whitespace?(content_value) || trailing_extra_whitespace?(content_value)
          end

          # @rbs content: String
          def leading_extra_whitespace?(content) #: bool
            # Match 2 or more spaces at the start, but not if followed by newline
            # Matches TypeScript: content.startsWith("  ") && !content.startsWith("  \n")
            content.start_with?("  ") && !content.start_with?("  \n")
          end

          # @rbs content: String
          def trailing_extra_whitespace?(content) #: bool
            # Match 2 or more whitespace characters at the end, but only if content has no newlines
            # Matches TypeScript: !content.includes("\n") && /\s{2,}$/.test(content)
            !content.include?("\n") && content.match?(/\s{2,}\z/)
          end
        end
      end
    end
  end
end
