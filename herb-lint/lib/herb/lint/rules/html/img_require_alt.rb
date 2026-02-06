# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-img-require-alt.ts
# Documentation: https://herb-tools.dev/linter/rules/html-img-require-alt

module Herb
  module Lint
    module Rules
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
      class HtmlImgRequireAlt < VisitorRule
        def self.rule_name #: String
          "html-img-require-alt"
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
          tag_name(node) == "img"
        end
      end
    end
  end
end
