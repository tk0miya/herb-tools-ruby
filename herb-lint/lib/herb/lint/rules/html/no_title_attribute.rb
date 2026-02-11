# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-title-attribute.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-title-attribute

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows the `title` attribute on HTML elements.
        #
        # The `title` attribute is an accessibility concern because it is
        # unreliable for screen readers and does not work on touch devices.
        # Content should be made visible in the page instead.
        #
        # Good:
        #   <span>More info available</span>
        #
        # Bad:
        #   <span title="More info">Hover me</span>
        class NoTitleAttribute < VisitorRule
          def self.rule_name = "html-no-title-attribute" #: String
          def self.description = "Disallow use of `title` attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            name = attribute_name(node)

            if name&.downcase == "title"
              add_offense(
                message: "Avoid using the 'title' attribute; it is unreliable for screen readers and touch devices",
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
