# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-output-control-flow.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-output-control-flow

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Disallow using output ERB tags (`<%=`) for control flow statements like `if`,
        #   `unless`, `case`, `while`, etc. Control flow should be written with regular ERB
        #   tags (`<% ... %>`), since these do not produce output directly.
        #
        # Good:
        #   <% if condition %>
        #    Content here
        #   <% end %>
        #
        #   <%= user.name %>
        #
        # Bad:
        #   <%= if condition %>
        #    Content here
        #   <% end %>
        #
        #   <%= unless user.nil? %>
        #    Welcome!
        #   <% end %>
        #
        class NoOutputControlFlow < VisitorRule
          def self.rule_name #: String
            "erb-no-output-control-flow"
          end

          def self.description #: String
            "Disallow control flow statements in ERB output tags"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
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

          # @rbs override
          def visit_erb_else_node(node)
            check_output_tag(node, "else")
            super
          end

          # @rbs override
          def visit_erb_end_node(node)
            check_output_tag(node, "end")
            super
          end

          private

          # @rbs node: untyped
          # @rbs keyword: String
          def check_output_tag(node, keyword) #: void
            return unless output_tag?(node)

            add_offense(
              message: "Control flow statements like `#{keyword}` should not be used with output tags. " \
                       "Use `<% #{keyword} ... %>` instead.",
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
end
