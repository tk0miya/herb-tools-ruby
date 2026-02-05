# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-empty-attributes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-empty-attributes

module Herb
  module Lint
    module Rules
      # Rule that disallows empty attribute values.
      #
      # Empty attribute values are typically mistakes and should either
      # be removed or given a meaningful value. Some attributes like
      # `alt=""` are semantically valid (indicates a decorative image)
      # and are allowed.
      #
      # Good:
      #   <div class="container">
      #   <img alt="">
      #
      # Bad:
      #   <div class="">
      #   <input type="">
      class HtmlNoEmptyAttributes < VisitorRule
        # Attributes where an empty value is semantically valid.
        ALLOWED_EMPTY_ATTRIBUTES = %w[alt].freeze #: Array[String]

        def self.rule_name #: String
          "html-no-empty-attributes"
        end

        def self.description #: String
          "Disallow empty attribute values"
        end

        def self.default_severity #: String
          "warning"
        end

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
