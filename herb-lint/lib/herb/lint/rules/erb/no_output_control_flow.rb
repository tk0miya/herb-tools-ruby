# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-output-control-flow.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-output-control-flow

module Herb
  module Lint
    module Rules
      # Rule that disallows control flow statements in ERB output tags.
      #
      # Control flow keywords (if, unless, case, while, for, until) should use
      # silent tags (`<% %>`) instead of output tags (`<%= %>`).
      #
      # Good:
      #   <% if condition %>
      #   <% case value %>
      #   <% while loop %>
      #
      # Bad:
      #   <%= if condition %>
      #   <%= case value %>
      #   <%= while loop %>
      class ErbNoOutputControlFlow < VisitorRule
        def self.rule_name #: String
          "erb-no-output-control-flow"
        end

        def self.description #: String
          "Disallow control flow statements in ERB output tags"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_if_node(node)
          check_output_tag(node, "if")
          super
        end

        # @rbs override
        def visit_erb_unless_node(node)
          check_output_tag(node, "unless")
          super
        end

        # @rbs override
        def visit_erb_case_node(node)
          check_output_tag(node, "case")
          super
        end

        # @rbs override
        def visit_erb_case_match_node(node)
          check_output_tag(node, "case")
          super
        end

        # @rbs override
        def visit_erb_while_node(node)
          check_output_tag(node, "while")
          super
        end

        # @rbs override
        def visit_erb_for_node(node)
          check_output_tag(node, "for")
          super
        end

        # @rbs override
        def visit_erb_until_node(node)
          check_output_tag(node, "until")
          super
        end

        private

        # @rbs node: untyped
        # @rbs keyword: String
        def check_output_tag(node, keyword) #: void
          return unless output_tag?(node)

          add_offense(
            message: "Use '<% #{keyword} %>' instead of '<%= #{keyword} %>' for control flow",
            location: node.location
          )
        end

        # @rbs node: untyped
        def output_tag?(node) #: bool
          node.tag_opening.value == "<%="
        end
      end
    end
  end
end
