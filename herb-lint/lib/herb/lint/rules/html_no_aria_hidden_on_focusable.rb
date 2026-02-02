# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows `aria-hidden="true"` on focusable elements.
      #
      # Applying `aria-hidden="true"` to a focusable element hides it from
      # assistive technologies while it remains reachable via keyboard,
      # causing confusion for screen reader users.
      #
      # An element is considered focusable when:
      # - It is a natively interactive element (`button`, `input`, `select`,
      #   `textarea`, `summary`, or `<a>` with `href`) and does not have a
      #   negative `tabindex`.
      # - It is a non-interactive element (or `<a>` without `href`) that has
      #   an explicit `tabindex` of 0 or greater.
      #
      # Good:
      #   <div aria-hidden="true">Decorative</div>
      #   <button>Click</button>
      #   <button tabindex="-1" aria-hidden="true">Removed from tab order</button>
      #
      # Bad:
      #   <button aria-hidden="true">Click</button>
      #   <a href="/page" aria-hidden="true">Link</a>
      #   <div tabindex="0" aria-hidden="true">Focusable div</div>
      class HtmlNoAriaHiddenOnFocusable < VisitorRule
        # Elements that are natively interactive/focusable.
        INTERACTIVE_ELEMENTS = Set.new(%w[a button input select summary textarea]).freeze #: Set[String]

        def self.rule_name #: String
          "html-no-aria-hidden-on-focusable"
        end

        def self.description #: String
          "Disallow aria-hidden=\"true\" on focusable elements"
        end

        def self.default_severity #: String
          "error"
        end

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
