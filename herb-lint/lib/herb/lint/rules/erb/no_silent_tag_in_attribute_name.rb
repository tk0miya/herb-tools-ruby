# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-silent-tag-in-attribute-name.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-silent-tag-in-attribute-name

module Herb
  module Lint
    module Rules
      # Rule that disallows silent ERB tags within HTML attribute names.
      #
      # Silent ERB tags (<%>, <%->, <%#>) do not output content and cannot
      # form part of an attribute name. This rule does not prevent using
      # silent tags for conditional attribute logic in the attribute list.
      #
      # Good:
      #   <div data-<%= key %>-target="value"></div>
      #   <div <%= data_attributes_for(user) %>></div>
      #   <div <% if valid? %>data-valid="true"<% end %>></div>
      #
      # Bad:
      #   <div data-<% key %>-target="value"></div>
      #   <div prefix-<%- variable -%>-suffix="test"></div>
      #   <span id-<%# comment %>-name="test"></span>
      class ErbNoSilentTagInAttributeName < VisitorRule
        def self.rule_name #: String
          "erb-no-silent-tag-in-attribute-name"
        end

        def self.description #: String
          "Disallow ERB silent tags within HTML attribute names"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_html_element_node(node)
          check_attributes(node)
          super
        end

        SILENT_TAG_OPENINGS = ["<%", "<%-", "<%#"].freeze #: Array[String]

        private

        # @rbs node: Herb::AST::HTMLElementNode
        def check_attributes(node) #: void
          attributes(node).each do |attr|
            check_attribute_name(attr)
          end
        end

        # @rbs attr_node: Herb::AST::HTMLAttributeNode
        def check_attribute_name(attr_node) #: void
          attr_node.name.children.each do |name_child|
            next unless name_child.is_a?(Herb::AST::ERBContentNode)
            next unless silent_tag?(name_child)

            add_offense(
              message: "Remove silent ERB tag from HTML attribute name. " \
                       "Silent ERB tags (#{name_child.tag_opening.value}) do not output content " \
                       "and should not be used in attribute names.",
              location: name_child.location
            )
          end
        end

        # @rbs node: Herb::AST::ERBContentNode
        def silent_tag?(node) #: bool
          SILENT_TAG_OPENINGS.include?(node.tag_opening.value)
        end
      end
    end
  end
end
