# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-anchor-require-href.ts
# Documentation: https://herb-tools.dev/linter/rules/html-anchor-require-href

module Herb
  module Lint
    module Rules
      module Html
        # Rule that requires href attribute on anchor elements.
        #
        # Anchor elements should have an href attribute to function
        # as proper hyperlinks. Without href, the anchor element
        # does not behave as a link.
        #
        # Good:
        #   <a href="/page">Click here</a>
        #   <a href="#">Click here</a>
        #
        # Bad:
        #   <a>Click here</a>
        #   <a name="anchor">Section</a>
        class AnchorRequireHref < VisitorRule
          def self.rule_name #: String
            "html-anchor-require-href"
          end

          def self.description #: String
            "Require href attribute on anchor elements"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            if anchor_element?(node) && !attribute?(node, "href")
              add_offense(
                message: "Missing href attribute on anchor element",
                location: node.location
              )
            end
            super
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
