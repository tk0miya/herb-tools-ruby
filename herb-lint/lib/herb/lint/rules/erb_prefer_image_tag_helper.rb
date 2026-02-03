# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that prefers Rails image_tag helper over raw <img> tags.
      #
      # In Rails applications, it's conventional to use the image_tag helper
      # instead of raw <img> HTML tags. The helper provides automatic asset
      # pipeline integration and better defaults.
      #
      # Good:
      #   <%= image_tag 'logo.png' %>
      #   <%= image_tag 'logo.png', alt: 'Company Logo' %>
      #
      # Bad:
      #   <img src="<%= asset_path('logo.png') %>">
      #   <img src="logo.png" alt="Logo">
      #
      # @see https://herb-tools.dev/linter/rules/erb-prefer-image-tag-helper Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-prefer-image-tag-helper.ts Source
      class ErbPreferImageTagHelper < VisitorRule
        def self.rule_name #: String
          "erb-prefer-image-tag-helper"
        end

        def self.description #: String
          "Prefer Rails image_tag helper over raw <img> tags"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_element_node(node)
          if img_element?(node)
            add_offense(
              message: "Prefer using <%= image_tag %> helper instead of <img> tag",
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
