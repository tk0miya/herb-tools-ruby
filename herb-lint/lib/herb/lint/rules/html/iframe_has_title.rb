# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-iframe-has-title.ts
# Documentation: https://herb-tools.dev/linter/rules/html-iframe-has-title

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that all `iframe` elements have a meaningful `title` attribute that describes the content of the
        #   frame. The title should not be empty or contain only whitespace.
        #
        # Good:
        #   <iframe src="https://youtube.com/embed/123" title="Product demonstration video"></iframe>
        #   <iframe src="https://example.com" title="Example website content"></iframe>
        #
        #   <!-- Hidden from screen readers -->
        #   <iframe aria-hidden="true"></iframe>
        #
        # Bad:
        #   <iframe src="https://example.com"></iframe>
        #
        #   <iframe src="https://example.com" title=""></iframe>
        #
        #   <iframe src="https://example.com" title=" "></iframe>
        #
        class IframeHasTitle < VisitorRule
          def self.rule_name = "html-iframe-has-title" #: String
          def self.description = "Require title attribute on iframe elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if iframe_element?(node) && !aria_hidden?(node) && !valid_title?(node)
              add_offense(
                message: "Missing or empty title attribute on iframe element",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def iframe_element?(node) #: bool
            tag_name(node) == "iframe"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def aria_hidden?(node) #: bool
            value = attribute_value(find_attribute(node, "aria-hidden"))
            value == "true"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def valid_title?(node) #: bool
            value = attribute_value(find_attribute(node, "title"))
            !value.nil? && !value.strip.empty?
          end
        end
      end
    end
  end
end
