# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-img-require-alt.ts
# Documentation: https://herb-tools.dev/linter/rules/html-img-require-alt

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Enforce that all `<img>` elements include an `alt` attribute.
        #
        # Good:
        #   <img src="/logo.png" alt="Company logo">
        #
        #   <img src="/avatar.jpg" alt="<%= user.name %>'s profile picture">
        #
        #   <img src="/divider.png" alt="">
        #
        #   <%= image_tag image_path("logo.png"), alt: "Company logo" %>
        #
        # Bad:
        #   <img src="/logo.png">
        #
        #   <img src="/avatar.jpg" alt> <!-- TODO -->
        #
        #   <%= image_tag image_path("logo.png") %> <!-- TODO -->
        #
        class ImgRequireAlt < VisitorRule
          def self.rule_name = "html-img-require-alt" #: String
          def self.description = "Require alt attribute on img tags" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

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
