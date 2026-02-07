# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-empty-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-empty-tags

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        # Disallow ERB tags (`<% %>` or `<%= %>`) that contain no meaningful content i.e., tags that are
        # completely empty or contain only whitespace.
        #
        # Rationale:
        # Empty ERB tags serve no purpose and may confuse readers or indicate incomplete code. They clutter the
        # template and may have been left behind accidentally after editing.
        #
        # Good:
        #   <%= user.name %>
        #
        #   <% if user.admin? %>
        #     Admin tools
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
          def self.rule_name #: String
            "erb-no-empty-tags"
          end

          def self.description #: String
            "Disallow empty ERB tags"
          end

          def self.default_severity #: String
            "error"
          end

          def self.autocorrectable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            if empty_tag?(node)
              add_offense_with_autofix(
                message: "ERB tag should not be empty. Remove empty ERB tags or add content.",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
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
