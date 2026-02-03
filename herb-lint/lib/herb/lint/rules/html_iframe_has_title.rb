# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that requires title attribute on iframe elements.
      #
      # Iframes must have a title attribute to provide an accessible name
      # for screen reader users to understand the content of the iframe.
      #
      # Good:
      #   <iframe src="content.html" title="Embedded content"></iframe>
      #
      # Bad:
      #   <iframe src="content.html"></iframe>
      #   <iframe src="content.html" title=""></iframe>
      #
      # @see https://herb-tools.dev/linter/rules/html-iframe-has-title Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-iframe-has-title.ts Source
      class HtmlIframeHasTitle < VisitorRule
        def self.rule_name #: String
          "html-iframe-has-title"
        end

        def self.description #: String
          "Require title attribute on iframe elements"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_html_element_node(node)
          if iframe_element?(node) && !valid_title?(node)
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
        def valid_title?(node) #: bool
          value = attribute_value(find_attribute(node, "title"))
          !value.nil? && !value.strip.empty?
        end
      end
    end
  end
end
