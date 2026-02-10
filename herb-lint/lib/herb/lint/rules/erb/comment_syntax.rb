# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-comment-syntax.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-comment-syntax

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Disallow ERB tags that start with `<% #` (with a space before the `#`).
        #   Use the ERB comment syntax `<%#` instead.
        #
        # Good:
        #   <%# This is a proper ERB comment %>
        #
        #   <%
        #     # This is a proper ERB comment
        #   %>
        #
        #   <%
        #     # Multi-line Ruby comment
        #     # spanning multiple lines
        #   %>
        #
        # Bad:
        #   <% # This should be an ERB comment %>
        #
        #   <%= # This should also be an ERB comment %>
        #
        #   <%== # This should also be an ERB comment %>
        class CommentSyntax < VisitorRule
          def self.rule_name = "erb-comment-syntax" #: String
          def self.description = "Enforce ERB comment style" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_erb_content_node(node)
            content = node.content.value

            if content.match?(/\A +#/)
              add_offense_with_autofix(
                message: offense_message(node.tag_opening.value, content),
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs node: Herb::AST::ERBContentNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            tag_opening = copy_token(node.tag_opening, content: "<%#")

            new_content_value = node.content.value.sub(/\A +#/, "")
            content = copy_token(node.content, content: new_content_value)

            new_node = copy_erb_content_node(node, tag_opening:, content:)

            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs opening_tag: String
          # @rbs content: String
          def offense_message(opening_tag, content) #: String
            if content.include?("herb:disable")
              "Use `<%#` instead of `#{opening_tag} #` for `herb:disable` directives. " \
                "Herb directives only work with ERB comment syntax (`<%# ... %>`)."
            else
              "Use `<%#` instead of `#{opening_tag} #`. " \
                "Ruby comments immediately after ERB tags can cause parsing issues."
            end
          end
        end
      end
    end
  end
end
