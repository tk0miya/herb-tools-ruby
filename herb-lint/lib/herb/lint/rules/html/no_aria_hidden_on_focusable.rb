# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-aria-hidden-on-focusable.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-aria-hidden-on-focusable

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Prevent using `aria-hidden="true"` on elements that can receive keyboard focus. When an element is
        #   focusable but hidden from screen readers, it creates a confusing experience where keyboard users can tab to
        #   "invisible" elements.
        #
        # Good:
        #   <button>Submit</button>
        #   <a href="/link">Link</a>
        #   <input type="text" autocomplete="off">
        #   <textarea></textarea>
        #
        #   <div aria-hidden="true">Decorative content</div>
        #   <span aria-hidden="true">🎉</span>
        #
        #   <button tabindex="-1" aria-hidden="true">Hidden button</button>
        #
        # Bad:
        #   <button aria-hidden="true">Submit</button>
        #
        #   <a href="/link" aria-hidden="true">Link</a>
        #
        #   <input type="text" autocomplete="off" aria-hidden="true">
        #
        #   <textarea aria-hidden="true"></textarea>
        #
        #   <select aria-hidden="true">
        #     <option>Option</option>
        #   </select>
        #
        #   <div tabindex="0" aria-hidden="true">Focusable div</div>
        #
        #   <a href="/link" aria-hidden="true">Hidden link</a>
        #
        class NoAriaHiddenOnFocusable < VisitorRule
          # Elements that are natively interactive/focusable.
          INTERACTIVE_ELEMENTS = Set.new(%w[a button input select summary textarea]).freeze #: Set[String]

          def self.rule_name = "html-no-aria-hidden-on-focusable" #: String
          def self.description = "Disallow aria-hidden=\"true\" on focusable elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if aria_hidden_true?(node) && focusable?(node)
              add_offense(
                message: "Elements that are focusable should not have `aria-hidden=\"true\"` " \
                         "because it will cause confusion for assistive technology users.",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def aria_hidden_true?(node) #: bool
            attribute_value(find_attribute(node, "aria-hidden"))&.downcase == "true"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def focusable?(node) #: bool
            tag = tag_name(node)
            return false if tag.nil?

            natively_focusable = tag == "a" ? attribute?(node, "href") : INTERACTIVE_ELEMENTS.include?(tag)
            natively_focusable ? not_negative_tabindex?(node) : non_negative_tabindex?(node)
          end

          # Returns true unless tabindex is explicitly negative.
          # @rbs node: Herb::AST::HTMLElementNode
          def not_negative_tabindex?(node) #: bool
            tab_index = tab_index_value(node)
            tab_index.nil? || tab_index >= 0
          end

          # Returns true only when tabindex is present and non-negative.
          # @rbs node: Herb::AST::HTMLElementNode
          def non_negative_tabindex?(node) #: bool
            tab_index = tab_index_value(node)
            !tab_index.nil? && tab_index >= 0
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def tab_index_value(node) #: Integer?
            value = attribute_value(find_attribute(node, "tabindex"))
            return nil if value.nil? || value.empty?

            Integer(value, exception: false)
          end
        end
      end
    end
  end
end
