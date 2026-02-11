# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-anchor-require-href.ts
# Documentation: https://herb-tools.dev/linter/rules/html-anchor-require-href

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow the use of anchor tags without an `href` attribute in HTML templates. Use if you want to
        #   perform an action without having the user navigated to a new URL.
        #
        # Good:
        #   <a href="https://alink.com">I'm a real link</a>
        #
        # Bad:
        #   <a data-action="click->doSomething">I'm a fake link</a>
        #
        class AnchorRequireHref < VisitorRule
          def self.rule_name = "html-anchor-require-href" #: String
          def self.description = "Require href attribute on anchor elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if anchor_element?(node) && !attribute?(node, "href")
              add_offense(
                message: "Add an `href` attribute to `<a>` to ensure it is focusable and accessible.",
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
