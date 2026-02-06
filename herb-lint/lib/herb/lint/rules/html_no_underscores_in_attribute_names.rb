# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-underscores-in-attribute-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-underscores-in-attribute-names

module Herb
  module Lint
    module Rules
      # Rule that disallows underscores in HTML attribute names.
      #
      # HTML attribute names conventionally use hyphens as word separators.
      # Underscores are not standard and should be replaced with hyphens.
      #
      # Good:
      #   <div data-value="foo">
      #
      # Bad:
      #   <div data_value="foo">
      class HtmlNoUnderscoresInAttributeNames < VisitorRule
        def self.rule_name #: String
          "html-no-underscores-in-attribute-names"
        end

        def self.description #: String
          "Disallow underscores in HTML attribute names"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_attribute_node(node)
          name = attribute_name(node)

          if name&.include?("_")
            add_offense(
              message: "Attribute name '#{name}' should not contain underscores; use hyphens instead",
              location: node.location
            )
          end
          super
        end
      end
    end
  end
end
