# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-role-heading-requires-level.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-role-heading-requires-level

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that any element with `role="heading"` also has a valid `aria-level` attribute. The
        #   `aria-level` defines the heading level (1–6) and is required for assistive technologies to properly
        #   interpret the document structure.
        #
        # Good:
        #   <div role="heading" aria-level="2">Section Title</div>
        #
        #   <span role="heading" aria-level="1">Main Title</span>
        #
        # Bad:
        #   <div role="heading">Section Title</div>
        #
        #   <span role="heading">Main Title</span>
        #
        class AriaRoleHeadingRequiresLevel < VisitorRule
          def self.rule_name = "html-aria-role-heading-requires-level" #: String
          def self.description = "Require aria-level on elements with role=\"heading\"" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if role_heading?(node) && !attribute?(node, "aria-level")
              add_offense(
                message: "Element with `role=\"heading\"` must have an `aria-level` attribute.",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def role_heading?(node) #: bool
            attribute_value(find_attribute(node, "role"))&.downcase == "heading"
          end
        end
      end
    end
  end
end
