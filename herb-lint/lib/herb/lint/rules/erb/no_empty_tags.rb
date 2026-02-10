# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-empty-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-empty-tags

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Disallow ERB tags (<% %> or <%= %>) that contain no meaningful content i.e., tags
        #   that are completely empty or contain only whitespace.
        #
        # Good:
        #   <%= user.name %>
        #
        #   <% if user.admin? %>
        #    Admin tools
        #   <% end %>
        #
        # Bad:
        #   <% %>
        #
        #   <%= %>
        #
        #   <%
        #   %>
        #
        class NoEmptyTags < VisitorRule
          def self.rule_name = "erb-no-empty-tags" #: String
          def self.description = "Disallow empty ERB tags" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_erb_content_node(node)
            if empty_tag?(node)
              add_offense_with_autofix(
                message: "Remove empty ERB tag",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs node: Herb::AST::ERBContentNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            # Remove the empty ERB tag from the AST
            remove_node(parse_result, node)
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def empty_tag?(node) #: bool
            # An empty tag is one where the content is nil, empty, or only whitespace
            content_value = node.content&.value
            content_value.nil? || content_value.strip.empty?
          end
        end
      end
    end
  end
end
