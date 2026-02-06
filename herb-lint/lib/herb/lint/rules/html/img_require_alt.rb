# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-img-require-alt.ts
# Documentation: https://herb-tools.dev/linter/rules/html-img-require-alt

module Herb
  module Lint
    module Rules
      module Html
        # Validates that HTML <img> elements include the required alt attribute for accessibility compliance.
        #
        # The alt attribute provides a text alternative for images, which is essential for:
        # - Screen readers to describe images to visually impaired users
        # - Displaying fallback text when images fail to load
        # - Search engine optimization
        #
        # Use alt="" for decorative images that don't convey meaningful information.
        # Use alt="description" for informative images with a clear, concise description.
        #
        # Good:
        #   <img src="/logo.png" alt="Company logo">
        #   <img src="/divider.png" alt="">
        #   <img src="/avatar.jpg" alt="<%= user.name %>'s profile picture">
        #
        # Bad:
        #   <img src="/logo.png">
        #   <img src="/logo.png" />
        class ImgRequireAlt < VisitorRule
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
                message: "Missing required `alt` attribute on `<img>` tag. " \
                         "Add `alt=\"\"` for decorative images or `alt=\"description\"` for informative images.",
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
end
