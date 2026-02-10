# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-avoid-both-disabled-and-aria-disabled.ts
# Documentation: https://herb-tools.dev/linter/rules/html-avoid-both-disabled-and-aria-disabled

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows using both `disabled` and `aria-disabled` on the same element.
        #
        # Using both attributes is redundant and potentially confusing.
        # Use one or the other, but not both.
        #
        # Good:
        #   <button disabled>Submit</button>
        #   <button aria-disabled="true">Submit</button>
        #
        # Bad:
        #   <button disabled aria-disabled="true">Submit</button>
        class AvoidBothDisabledAndAriaDisabled < VisitorRule
          def self.rule_name = "html-avoid-both-disabled-and-aria-disabled" #: String
          def self.description = "Disallow using both `disabled` and `aria-disabled` on the same element" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if attribute?(node, "disabled") && attribute?(node, "aria-disabled")
              add_offense(
                message: "Avoid using both 'disabled' and 'aria-disabled' on the same element; they are redundant",
                location: node.location
              )
            end
            super
          end
        end
      end
    end
  end
end
