# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module A11y
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
        class IframeHasTitle < VisitorRule
          def self.rule_name #: String
            "a11y/iframe-has-title"
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
            node.tag_name&.value&.downcase == "iframe"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def valid_title?(node) #: bool
            title_attr = find_title_attribute(node)
            return false unless title_attr

            non_empty_value?(title_attr)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def find_title_attribute(node) #: Herb::AST::HTMLAttributeNode?
            return nil unless node.open_tag

            node.open_tag.children.find do |child|
              child.is_a?(Herb::AST::HTMLAttributeNode) &&
                child.name.children.first&.content&.downcase == "title"
            end
          end

          # @rbs attr: Herb::AST::HTMLAttributeNode
          def non_empty_value?(attr) #: bool
            value = attr.value
            return false unless value

            content = value.children.first&.content
            !content.nil? && !content.strip.empty?
          end
        end
      end
    end
  end
end
