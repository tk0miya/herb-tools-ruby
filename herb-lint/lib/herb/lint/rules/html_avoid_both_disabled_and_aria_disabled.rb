# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      class HtmlAvoidBothDisabledAndAriaDisabled < VisitorRule
        def self.rule_name #: String
          "html-avoid-both-disabled-and-aria-disabled"
        end

        def self.description #: String
          "Disallow using both `disabled` and `aria-disabled` on the same element"
        end

        def self.default_severity #: String
          "warning"
        end

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
