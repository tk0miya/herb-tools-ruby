# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-underscores-in-attribute-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-underscores-in-attribute-names

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when an HTML attribute name contains an underscore (`_`). According to the HTML
        #   specification, attribute names should use only lowercase letters, digits, hyphens (`-`),
        #   and colons (`:`) in specific namespaces. Underscores are not valid in standard HTML
        #   attribute names and may lead to unpredictable behavior or be ignored by browsers entirely.
        #
        # Good:
        #   <div data-user-id="123"></div>
        #
        #   <img aria-label="Close" alt="Close">
        #
        # Bad:
        #   <div data_user_id="123"></div>
        #
        #   <img aria_label="Close" alt="Close">
        #
        class NoUnderscoresInAttributeNames < VisitorRule
          def self.rule_name = "html-no-underscores-in-attribute-names" #: String
          def self.description = "Disallow underscores in HTML attribute names" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

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
end
