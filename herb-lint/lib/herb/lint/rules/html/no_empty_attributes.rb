# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-empty-attributes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-empty-attributes

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when certain restricted attributes are present but have an empty string as their value.
        #   These attributes are required to have meaningful values to function properly, and leaving
        #   them empty is typically either a mistake or unnecessary.
        #
        #   In most cases, if the value is not available, it's better to omit the attribute entirely.
        #
        #   Restricted attributes:
        #
        #   - id
        #   - class
        #   - name
        #   - for
        #   - src
        #   - href
        #   - title
        #   - data
        #   - role
        #   - data-*
        #   - aria-*
        #
        # Good:
        #   <div id="header"></div>
        #   <img src="/logo.png" alt="Company logo">
        #   <input type="text" name="email" autocomplete="off">
        #
        #   <!-- Dynamic attributes with meaningful values -->
        #   <div data-<%= key %>="<%= value %>" aria-<%= prop %>="<%= description %>">
        #     Dynamic content
        #   </div>
        #
        #   <!-- if no class should be set, omit it completely -->
        #   <div>Plain div</div>
        #
        # Bad:
        #   <div id=""></div>
        #   <img src="" alt="Company logo">
        #   <input name="" autocomplete="off">
        #
        #   <div data-config="">Content</div>
        #   <button aria-label="">×</button>
        #
        #   <div class="">Plain div</div>
        #
        class NoEmptyAttributes < VisitorRule
          # Attributes where an empty value is semantically valid.
          ALLOWED_EMPTY_ATTRIBUTES = %w[alt].freeze #: Array[String]

          def self.rule_name = "html-no-empty-attributes" #: String
          def self.description = "Disallow empty attribute values" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            check_empty_attributes(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_empty_attributes(node) #: void
            attributes(node).each do |attr|
              name = attribute_name(attr)
              next if name.nil?
              next if ALLOWED_EMPTY_ATTRIBUTES.include?(name.downcase)
              next unless empty_value?(attr)

              add_offense(
                message: "Unexpected empty attribute value for '#{name}'",
                location: attr.location
              )
            end
          end

          # Check if an attribute has an explicit but empty value.
          # Boolean attributes (no value) return false.
          #
          # @rbs node: Herb::AST::HTMLAttributeNode
          def empty_value?(node) #: bool
            value = node.value
            # Boolean attributes (no value at all) are not "empty"
            return false if value.nil?

            content = value.children.first&.content
            content.nil? || content.empty?
          end
        end
      end
    end
  end
end
