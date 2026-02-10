# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-nested-links.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-nested-links

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows nesting of anchor elements.
        #
        # Nesting anchor elements is invalid HTML and causes unpredictable
        # behavior across browsers. Each anchor should be a separate,
        # non-nested element.
        #
        # Good:
        #   <a href="/page">Link</a>
        #
        # Bad:
        #   <a href="/outer">
        #     <a href="/inner">Nested link</a>
        #   </a>
        class NoNestedLinks < VisitorRule
          def self.rule_name = "html-no-nested-links" #: String
          def self.description = "Disallow nesting of anchor elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @anchor_depth: Integer

          # @rbs override
          def on_new_investigation #: void
            super
            @anchor_depth = 0
          end

          # @rbs override
          def visit_html_element_node(node)
            if anchor_element?(node)
              if @anchor_depth.positive?
                add_offense(
                  message: "Nested anchor element found inside another anchor element",
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
