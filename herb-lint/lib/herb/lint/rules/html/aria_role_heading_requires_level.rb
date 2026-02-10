# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-role-heading-requires-level.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-role-heading-requires-level

module Herb
  module Lint
    module Rules
      module Html
        # Rule that requires aria-level on elements with role="heading".
        #
        # Elements with `role="heading"` must include an `aria-level` attribute
        # to indicate the heading level to assistive technologies.
        #
        # Good:
        #   <div role="heading" aria-level="2">Title</div>
        #
        # Bad:
        #   <div role="heading">Title</div>
        class AriaRoleHeadingRequiresLevel < VisitorRule
          def self.rule_name #: String
            "html-aria-role-heading-requires-level"
          end

          def self.description #: String
            "Require aria-level on elements with role=\"heading\""
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

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
