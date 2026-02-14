# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-navigation-has-label.ts
# Documentation: https://herb-tools.dev/linter/rules/html-navigation-has-label

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that navigation landmarks have a unique accessible name via `aria-label` or `aria-labelledby`
        #   attributes. This applies to both `<nav>` elements and elements with `role="navigation"`.
        #
        # Good:
        #   <nav aria-label="Main navigation">
        #     <ul>
        #       <li><a href="/">Home</a></li>
        #       <li><a href="/about">About</a></li>
        #     </ul>
        #   </nav>
        #
        #   <nav aria-labelledby="breadcrumb-title">
        #     <h2 id="breadcrumb-title">Breadcrumb</h2>
        #     <ol>
        #       <li><a href="/">Home</a></li>
        #       <li>Current Page</li>
        #     </ol>
        #   </nav>
        #
        #   <div role="navigation" aria-label="Footer links">
        #     <a href="/privacy">Privacy</a>
        #     <a href="/terms">Terms</a>
        #   </div>
        #
        # Bad:
        #   <nav>
        #     <ul>
        #       <li><a href="/">Home</a></li>
        #       <li><a href="/about">About</a></li>
        #     </ul>
        #   </nav>
        #
        #   <div role="navigation">
        #     <a href="/privacy">Privacy</a>
        #     <a href="/terms">Terms</a>
        #   </div>
        #
        class NavigationHasLabel < VisitorRule
          def self.rule_name = "html-navigation-has-label" #: String
          def self.description = "Require accessible label on nav elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if navigation_element?(node) && !label?(node)
              add_offense(
                message: navigation_message(node),
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def navigation_element?(node) #: bool
            tag_name(node) == "nav" || role_navigation?(node)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def role_navigation?(node) #: bool
            role = attribute_value(find_attribute(node, "role"))
            role == "navigation"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def navigation_message(node) #: String
            base_message = "The navigation landmark should have a unique accessible name via " \
                           "`aria-label` or `aria-labelledby`"
            if role_navigation?(node)
              "#{base_message}. Consider replacing `role=\"navigation\"` with a native `<nav>` element."
            else
              base_message
            end
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
