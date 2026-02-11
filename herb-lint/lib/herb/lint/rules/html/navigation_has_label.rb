# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-navigation-has-label.ts
# Documentation: https://herb-tools.dev/linter/rules/html-navigation-has-label

module Herb
  module Lint
    module Rules
      module Html
        # Rule that requires navigation elements to have an accessible label.
        #
        # `<nav>` elements should have an `aria-label` or `aria-labelledby`
        # attribute to provide an accessible name for screen reader users.
        #
        # Good:
        #   <nav aria-label="Main navigation"><a href="/">Home</a></nav>
        #   <nav aria-labelledby="nav-heading"><a href="/">Home</a></nav>
        #
        # Bad:
        #   <nav><a href="/">Home</a></nav>
        class NavigationHasLabel < VisitorRule
          def self.rule_name = "html-navigation-has-label" #: String
          def self.description = "Require accessible label on nav elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if nav_element?(node) && !label?(node)
              add_offense(
                message: "Missing accessible label (`aria-label` or `aria-labelledby`) on nav element",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def nav_element?(node) #: bool
            tag_name(node) == "nav"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def label?(node) #: bool
            valid_attribute?(node, "aria-label") || valid_attribute?(node, "aria-labelledby")
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs attr_name: String
          def valid_attribute?(node, attr_name) #: bool
            value = attribute_value(find_attribute(node, attr_name))
            !value.nil? && !value.strip.empty?
          end
        end
      end
    end
  end
end
