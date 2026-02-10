# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-whitespace-inside-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-require-whitespace-inside-tags

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Require a single space before and after Ruby code inside ERB tags (< % ... % > and < %= ... % >).
        #   This improves readability and keeps ERB code visually consistent with Ruby style guides.
        #
        # Good:
        #   <%= user.name %>
        #
        #   <% if admin %>
        #     Hello, admin.
        #   <% end %>
        #
        # Bad:
        #   <%=user.name %>
        #
        #   <%if admin %>
        #
        #     Hello, admin.
        #   <% end%>
        #
        class RequireWhitespaceInsideTags < VisitorRule
          def self.rule_name = "erb-require-whitespace-inside-tags" #: String
          def self.description = "Require whitespace inside ERB tag delimiters" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_child_nodes(node)
            # Check all ERB nodes for whitespace requirements
            check_node_whitespace(node) if node.class.name.start_with?("Herb::AST::ERB")
            super
          end

          # @rbs node: Herb::AST::Node
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            content_value = node.content&.value
            return false if content_value.nil?

            content_value = fix_whitespace(node, content_value)
            content = copy_token(node.content, content: content_value)
            new_node = copy_erb_node(node, content:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::Node
          # @rbs content_value: String
          def fix_whitespace(node, content_value) #: String
            if commented_output_tag?(node, content_value)
              # Special handling for comment tags with <%#=
              content_value.sub!(/^=(\S)/, "= \\1") unless content_value.start_with?("= ", "=\t", "=\n")
            else
              # Regular whitespace handling (including <%# without =)
              content_value = " #{content_value}" unless content_value.start_with?(" ", "\t", "\n")
            end

            content_value = "#{content_value} " unless content_value.end_with?(" ", "\t", "\n")
            content_value
          end

          # @rbs node: Herb::AST::Node
          def check_node_whitespace(node) #: void
            return unless missing_whitespace?(node)

            # All ERB nodes support autofix using copy_erb_node
            add_offense_with_autofix(
              message: "Add whitespace inside ERB tag delimiters",
              location: node.location,
              node:
            )
          end

          # @rbs node: Herb::AST::Node
          def missing_whitespace?(node) #: bool
            content_value = node.content&.value
            return false if content_value.nil? || content_value.strip.empty?

            if commented_output_tag?(node, content_value)
              # Comment tags with <%#= require space after equals and before closing
              !content_value.start_with?("= ", "=\t", "=\n") ||
                !content_value.end_with?(" ", "\t", "\n")
            else
              # All other tags (including <%# without =) require whitespace at both ends
              !content_value.start_with?(" ", "\t", "\n") ||
                !content_value.end_with?(" ", "\t", "\n")
            end
          end

          # @rbs node: Herb::AST::Node
          # @rbs content_value: String
          def commented_output_tag?(node, content_value) #: bool
            node.tag_opening.value == "<%#" && content_value.start_with?("=")
          end
        end
      end
    end
  end
end
