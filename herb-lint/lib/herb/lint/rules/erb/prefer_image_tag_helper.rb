# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-prefer-image-tag-helper.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-prefer-image-tag-helper

module Herb
  module Lint
    module Rules
      module Erb
        # Flags manual <img> tags containing dynamic ERB expressions,
        # recommending the Rails image_tag helper instead.
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

          # @rbs override
          def visit_html_element_node(node)
            if img_element?(node)
              add_offense(
                message: "Prefer `image_tag` helper over manual `<img>` with dynamic ERB expressions. " \
                         "Use `<%= image_tag ... %>` instead.",
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
