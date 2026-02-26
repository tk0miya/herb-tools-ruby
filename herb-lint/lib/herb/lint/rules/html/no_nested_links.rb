# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-nested-links.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-nested-links

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow placing one `<a>` element inside another `<a>` element. Links must not contain
        #   other links as descendants.
        #
        # Good:
        #   <a href="/products">View products</a>
        #   <a href="/about">About us</a>
        #
        #   <%= link_to "View products", products_path %>
        #   <%= link_to about_path do %>
        #     About us
        #   <% end %>
        #
        # Bad:
        #   <a href="/products">
        #     View <a href="/special-offer">special offer</a>
        #   </a>
        #
        #   <%= link_to "Products", products_path do %>
        #     <%= link_to "Special offer", offer_path %> <!-- TODO -->
        #   <% end %>
        #
        class NoNestedLinks < VisitorRule
          def self.rule_name = "html-no-nested-links" #: String
          def self.description = "Disallow nesting of anchor elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @anchor_depth: Integer

          # @rbs override
          def on_new_investigation
            super
            @anchor_depth = 0
          end

          # @rbs override
          def visit_html_element_node(node)
            if anchor_element?(node)
              if @anchor_depth.positive?
                add_offense(
                  message: "Nested `<a>` elements are not allowed. Links cannot contain other links.",
                  location: node.location
                )
              end
              @anchor_depth += 1
              super
              @anchor_depth -= 1
            else
              super
            end
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def anchor_element?(node) #: bool
            tag_name(node) == "a"
          end
        end
      end
    end
  end
end
