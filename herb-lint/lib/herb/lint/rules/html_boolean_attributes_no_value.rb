# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-boolean-attributes-no-value.ts
# Documentation: https://herb-tools.dev/linter/rules/html-boolean-attributes-no-value

module Herb
  module Lint
    module Rules
      # Rule that disallows values on boolean HTML attributes.
      #
      # Boolean attributes are attributes that represent true/false values.
      # In HTML, the presence of the attribute represents true, and
      # absence represents false. They should not have a value assigned.
      #
      # Good:
      #   <input disabled>
      #   <input checked readonly>
      #
      # Bad:
      #   <input disabled="disabled">
      #   <input disabled="true">
      class HtmlBooleanAttributesNoValue < VisitorRule
        # Standard HTML boolean attributes.
        BOOLEAN_ATTRIBUTES = Set.new(
          %w[
            allowfullscreen
            async
            autofocus
            autoplay
            checked
            compact
            controls
            declare
            default
            defer
            disabled
            formnovalidate
            hidden
            itemscope
            loop
            multiple
            muted
            nohref
            noresize
            noshade
            novalidate
            nowrap
            open
            readonly
            required
            reversed
            scoped
            seamless
            selected
            sortable
            truespeed
            typemustmatch
          ]
        ).freeze #: Set[String]

        def self.rule_name #: String
          "html-boolean-attributes-no-value"
        end

        def self.description #: String
          "Boolean attributes should not have values"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_attribute_node(node)
          name = attribute_name(node)

          if name && boolean_attribute?(name) && node.value
            add_offense(
              message: "Boolean attribute '#{name}' should not have a value",
              location: node.location
            )
          end
          super
        end

        private

        # @rbs name: String
        def boolean_attribute?(name) #: bool
          BOOLEAN_ATTRIBUTES.include?(name.downcase)
        end
      end
    end
  end
end
