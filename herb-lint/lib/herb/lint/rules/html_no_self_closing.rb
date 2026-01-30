# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that enforces consistent self-closing style for void elements.
        #
        # Void elements (e.g., br, img, input) cannot have children, so
        # a trailing slash is unnecessary. This rule enforces omitting
        # the self-closing slash for consistency.
        #
        # Good:
        #   <br>
        #   <img src="photo.jpg">
        #   <input type="text">
        #
        # Bad:
        #   <br/>
        #   <img src="photo.jpg" />
        #   <input type="text" />
        class NoSelfClosing < VisitorRule
          VOID_ELEMENTS = %w[
            area
            base
            br
            col
            embed
            hr
            img
            input
            link
            meta
            param
            source
            track
            wbr
          ].freeze #: Array[String]

          def self.rule_name #: String
            "html-no-self-closing"
          end

          def self.description #: String
            "Consistent self-closing style for void elements"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            if void_element?(node) && self_closing?(node)
              add_offense(
                message: "Void element '#{tag_name(node)}' should not have a self-closing slash",
                location: node.open_tag.tag_closing.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def void_element?(node) #: bool
            name = tag_name(node)
            return false if name.nil?

            VOID_ELEMENTS.include?(name.downcase)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def self_closing?(node) #: bool
            return false unless node.open_tag

            node.open_tag.tag_closing&.value == "/>"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def tag_name(node) #: String?
            node.open_tag&.tag_name&.value
          end
        end
      end
    end
  end
end
