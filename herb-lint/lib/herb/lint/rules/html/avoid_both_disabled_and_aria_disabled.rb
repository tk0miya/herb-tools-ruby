# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-avoid-both-disabled-and-aria-disabled.ts
# Documentation: https://herb-tools.dev/linter/rules/html-avoid-both-disabled-and-aria-disabled

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Prevent using both the native `disabled` attribute and the `aria-disabled` attribute on the same HTML
        #   element. Elements should use either the native `disabled` attribute or `aria-disabled`, but not both.
        #
        # Good:
        #   <!-- Use only the native disabled attribute -->
        #   <button disabled>Submit</button>
        #   <input type="text" autocomplete="off" disabled>
        #
        #   <!-- Use only aria-disabled for custom elements -->
        #   <div role="button" aria-disabled="true">Custom Button</div>
        #
        #   <!-- Use only aria-disabled -->
        #   <button aria-disabled="true">Submit</button>
        #
        # Bad:
        #   <!-- Both disabled and aria-disabled -->
        #   <button disabled aria-disabled="true">Submit</button>
        #
        #   <input type="text" autocomplete="off" disabled aria-disabled="true">
        #
        #   <select disabled aria-disabled="true">
        #    <option>Option 1</option>
        #   </select>
        #
        class AvoidBothDisabledAndAriaDisabled < VisitorRule
          ELEMENTS_WITH_NATIVE_DISABLED_SUPPORT = %w[
            button
            fieldset
            input
            optgroup
            option
            select
            textarea
          ].freeze #: Array[String]

          def self.rule_name = "html-avoid-both-disabled-and-aria-disabled" #: String
          def self.description = "Disallow using both `disabled` and `aria-disabled` on the same element" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            check_element(node)
            super
          end

          private

          # @rbs node: Herb::HtmlElementNode -- Check if element has both disabled and aria-disabled
          def check_element(node) #: void
            return unless element_supports_native_disabled?(node)
            return if dynamic_disabled_attributes?(node)
            return unless both_disabled_attributes?(node)

            add_offense(
              message: "aria-disabled may be used in place of native HTML disabled to allow tab-focus on an " \
                       "otherwise ignored element. Setting both attributes is contradictory and confusing. " \
                       "Choose either disabled or aria-disabled, not both.",
              location: node.tag_name&.location || node.location
            )
          end

          # @rbs node: Herb::HtmlElementNode
          def element_supports_native_disabled?(node) #: bool
            element_tag_name = tag_name(node)
            return false unless element_tag_name

            ELEMENTS_WITH_NATIVE_DISABLED_SUPPORT.include?(element_tag_name)
          end

          # @rbs node: Herb::HtmlElementNode
          def both_disabled_attributes?(node) #: bool
            attribute?(node, "disabled") && attribute?(node, "aria-disabled")
          end

          # @rbs node: Herb::HtmlElementNode
          def dynamic_disabled_attributes?(node) #: bool
            return true if attribute?(node, "disabled") && attribute_has_erb_content?(node, "disabled")
            return true if attribute?(node, "aria-disabled") && attribute_has_erb_content?(node, "aria-disabled")

            false
          end

          # @rbs node: Herb::HtmlElementNode, attribute_name: String -- Check if attribute value contains ERB
          def attribute_has_erb_content?(node, attribute_name) #: bool
            attr = find_attribute(node, attribute_name)
            return false unless attr

            value = attr.value
            return false unless value

            value.children.any? { _1.class.name&.include?("ERB") }
          end
        end
      end
    end
  end
end
