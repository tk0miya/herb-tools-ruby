# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-output-control-flow.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-output-control-flow

module Herb
  module Lint
    module Rules
      module Erb
        # Control flow statements should not be used with output tags.
        class NoOutputControlFlow < VisitorRule
          def self.rule_name #: String
            "erb-no-output-control-flow"
          end

          def self.description #: String
            "Disallow control flow statements in ERB output tags"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def visit_erb_if_node(node)
            check_output_control_flow(node, "if")
            super
          end

          # @rbs override
          def visit_erb_unless_node(node)
            check_output_control_flow(node, "unless")
            super
          end

          # @rbs override
          def visit_erb_else_node(node)
            check_output_control_flow(node, "else")
            super
          end

          # @rbs override
          def visit_erb_end_node(node)
            check_output_control_flow(node, "end")
            super
          end

          private

          # @rbs node: untyped
          # @rbs control_block_type: String
          def check_output_control_flow(node, control_block_type) #: void
            open_tag = node.tag_opening
            return unless open_tag
            return unless open_tag.value == "<%="

            add_offense(
              message: "Control flow statements like `#{control_block_type}` should not be used with output tags. " \
                       "Use `<% #{control_block_type} ... %>` instead.",
              location: open_tag.location
            )
          end
        end
      end
    end
  end
end
