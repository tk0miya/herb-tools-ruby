# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      class HtmlNoNestedLinks < VisitorRule
        def self.rule_name #: String
          "html-no-nested-links"
        end

        def self.description #: String
          "Disallow nesting of anchor elements"
        end

        def self.default_severity #: String
          "error"
        end

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
