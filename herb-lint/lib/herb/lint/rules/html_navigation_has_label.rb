# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      class HtmlNavigationHasLabel < VisitorRule
        def self.rule_name #: String
          "html-navigation-has-label"
        end

        def self.description #: String
          "Require accessible label on nav elements"
        end

        def self.default_severity #: String
          "error"
        end

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
          node.tag_name&.value&.downcase == "nav"
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
