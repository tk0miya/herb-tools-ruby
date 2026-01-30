# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module A11y
        # Rule that requires alt attributes on img tags.
        #
        # Images must have an alt attribute to provide a text alternative
        # for screen readers and when images fail to load.
        #
        # Good:
        #   <img src="photo.jpg" alt="A sunset over the ocean">
        #   <img src="decorative.png" alt="">
        #
        # Bad:
        #   <img src="photo.jpg">
        class AltText < VisitorRule
          def self.rule_name #: String
            "alt-text"
          end

          def self.description #: String
            "Require alt attribute on img tags"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def visit_html_element_node(node)
            if img_element?(node) && !attribute?(node, "alt")
              add_offense(
                message: "Missing alt attribute on img tag",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def img_element?(node) #: bool
            node.tag_name&.value&.downcase == "img"
          end
        end
      end
    end
  end
end
