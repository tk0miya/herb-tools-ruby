# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-prefer-image-tag-helper.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-prefer-image-tag-helper

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Prefer using Rails' `image_tag` helper over manual `<img>` tags with dynamic ERB expressions
        #   like `image_path` or `asset_path`.
        #
        # Good:
        #   <%= image_tag "logo.png", alt: "Logo" %>
        #   <%= image_tag "banner.jpg", alt: "Banner", class: "hero-image" %>
        #   <%= image_tag "icon.svg", alt: "Icon", size: "24x24" %>
        #   <%= image_tag user.avatar.url, alt: "User avatar" %>
        #   <%= image_tag "#{root_url}/banner.jpg", alt: "Banner" %>
        #   <img src="/static/logo.png" alt="Logo">
        #
        # Bad:
        #   <img src="<%= image_path("logo.png") %>" alt="Logo">
        #   <img src="<%= asset_path("banner.jpg") %>" alt="Banner">
        #   <img src="<%= user.avatar.url %>" alt="User avatar">
        #   <img src="<%= product.image %>" alt="Product image">
        #   <img src="<%= Rails.application.routes.url_helpers.root_url %>/icon.png" alt="Logo">
        #   <img src="<%= root_url %>/banner.jpg" alt="Banner">
        #   <img src="<%= admin_path %>/icon.png" alt="Admin icon">
        #   <img src="<%= base_url %><%= image_path("logo.png") %>" alt="Logo">
        #   <img src="<%= root_path %><%= "icon.png" %>" alt="Icon">
        #
        class PreferImageTagHelper < VisitorRule
          def self.rule_name #: String
            "erb-prefer-image-tag-helper"
          end

          def self.description #: String
            "Prefer Rails image_tag helper over raw <img> tags"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # @rbs override
          def visit_html_element_node(node)
            return super unless tag_name(node) == "img"

            # Only report offense if src contains ERB content
            value = find_attribute(node, "src")&.value
            if value && contains_erb_content?(value) && !static_scheme?(value)
              add_offense(
                message: "Prefer using <%= image_tag %> helper instead of <img> tag",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs value: Herb::AST::HTMLAttributeValueNode
          def contains_erb_content?(value) #: bool
            value.children.any? do |child|
              child.class.name&.include?("ERB")
            end
          end

          # @rbs value: Herb::AST::HTMLAttributeValueNode
          def static_scheme?(value) #: bool
            first_child = value.children.first

            case first_child
            when Herb::AST::LiteralNode
              content = first_child.content.strip
              content.match?(%r{^(?:data:|https?://)})
            else
              false
            end
          end
        end
      end
    end
  end
end
