# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-positive-tab-index.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-positive-tab-index

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Prevent using positive values for the `tabindex` attribute. Only `tabindex="0"` (to make elements
        #   focusable) and `tabindex="-1"` (to remove from tab order) should be used.
        #
        # Good:
        #   <!-- Natural tab order (no tabindex needed) -->
        #   <button>First</button>
        #   <button>Second</button>
        #   <button>Third</button>
        #
        #   <!-- Make non-interactive element focusable -->
        #   <div tabindex="0" role="button">Custom button</div>
        #
        #   <!-- Remove from tab order but keep programmatically focusable -->
        #   <button tabindex="-1">Skip this in tab order</button>
        #
        #   <!-- Zero tabindex to ensure focusability -->
        #   <span tabindex="0" role="button">Focusable span</span>
        #
        # Bad:
        #   <button tabindex="3">Third in tab order</button>
        #
        #   <button tabindex="1">First in tab order</button>
        #
        #   <button tabindex="2">Second in tab order</button>
        #
        #   <input tabindex="5" type="text" autocomplete="off">
        #
        #   <button tabindex="10">Submit</button>
        #
        class NoPositiveTabIndex < VisitorRule
          def self.rule_name = "html-no-positive-tab-index" #: String
          def self.description = "Disallow positive tabindex values" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            if tabindex_attribute?(node)
              value = attribute_value(node)
              if positive_tabindex?(value)
                add_offense(
                  message: "Do not use positive `tabindex` values as they are error prone and can severely " \
                           "disrupt navigation experience for keyboard users. Use `tabindex=\"0\"` to make an " \
                           "element focusable or `tabindex=\"-1\"` to remove it from the tab sequence.",
                  location: node.location
                )
              end
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def tabindex_attribute?(node) #: bool
            attribute_name(node)&.downcase == "tabindex"
          end

          # @rbs value: String?
          def positive_tabindex?(value) #: bool
            return false if value.nil? || value.empty?

            integer_value = Integer(value, exception: false)
            return false if integer_value.nil?

            integer_value.positive?
          end
        end
      end
    end
  end
end
