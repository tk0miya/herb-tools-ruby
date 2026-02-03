# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      #
      # @see https://herb-tools.dev/linter/rules/html-no-title-attribute Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-title-attribute.ts Source
      class HtmlNoTitleAttribute < VisitorRule
        def self.rule_name #: String
          "html-no-title-attribute"
        end

        def self.description #: String
          "Disallow use of `title` attribute"
        end

        def self.default_severity #: String
          "warning"
        end

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
