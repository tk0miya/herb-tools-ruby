# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-right-trim.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-right-trim

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   This rule enforces the use of `-%>` for right-trimming ERB output tags (like `<%= %>`) instead of `=%>`.
        #
        # Good:
        #   <%= title -%>
        #
        #   <% if condition? %>
        #    <h1>Content</h1>
        #   <% end %>
        #
        #   <% items.each do |item| %>
        #    <li><%= item -%></li>
        #   <% end %>
        #
        # Bad:
        #   <%= title =%>
        #
        #   <% title =%>
        #
        #   <% if true =%>
        #    <h1>Content</h1>
        #   <% end %>
        #
        #   <% items.each do |item| =%>
        #    <li><%= item %></li>
        #   <% end %>
        #
        class RightTrim < VisitorRule
          def self.rule_name = "erb-right-trim" #: String
          def self.description = "Use `-%>` instead of `=%>` for right-trimming" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # Check each ERB node for the obscure =%> syntax
          # @rbs override
          def visit_child_nodes(node)
            check_erb_node(node) if node.class.name&.start_with?("Herb::AST::ERB")
            super
          end

          # @rbs node: Herb::AST::Node
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            tag_closing = copy_token(node.tag_closing, content: "-%>")
            new_node = copy_erb_node(node, tag_closing:)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: untyped
          def check_erb_node(node) #: void
            return unless node.tag_closing
            return unless node.tag_closing.value == "=%>"

            add_offense_with_autofix(
              message: "Use `-%>` instead of `=%>` for right-trimming. " \
                       "The `=%>` syntax is obscure and not well-supported in most ERB engines.",
              location: node.tag_closing.location,
              node:
            )
          end
        end
      end
    end
  end
end
