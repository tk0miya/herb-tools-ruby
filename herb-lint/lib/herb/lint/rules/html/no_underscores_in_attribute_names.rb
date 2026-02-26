# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-underscores-in-attribute-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-underscores-in-attribute-names

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when an HTML attribute name contains an underscore (`_`). According to the HTML specification,
        #   attribute names should use only lowercase letters, digits, hyphens (`-`), and colons (`:`) in
        #   specific namespaces (e.g., `xlink:href` in SVG). Underscores are not valid in standard HTML
        #   attribute names and may lead to unpredictable behavior or be ignored by browsers entirely.
        #
        # Good:
        #   <div data-user-id="123"></div>
        #
        #   <img aria-label="Close" alt="Close">
        #
        #   <div data-<%= key %>-attribute="value"></div>
        #
        # Bad:
        #   <div data_user_id="123"></div>
        #
        #   <img aria_label="Close" alt="Close">
        #
        #   <div data-<%= key %>_attribute="value"></div>
        #
        class NoUnderscoresInAttributeNames < VisitorRule
          def self.rule_name = "html-no-underscores-in-attribute-names" #: String
          def self.description = "Disallow underscores in HTML attribute names" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            if node.name.children.any? { _1.is_a?(Herb::AST::LiteralNode) && _1.content.include?("_") }
              name = full_attribute_name(node)
              add_offense(
                message: "Attribute `#{name}` should not contain underscores. Use hyphens (-) instead.",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def full_attribute_name(node) #: String
            node.name.children.map do |child|
              if child.is_a?(Herb::AST::LiteralNode)
                child.content
              elsif child.respond_to?(:tag_opening)
                "#{child.tag_opening.value}#{child.content.value}#{child.tag_closing.value}"
              else
                ""
              end
            end.join
          end
        end
      end
    end
  end
end
