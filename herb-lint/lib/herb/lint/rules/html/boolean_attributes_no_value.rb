# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-boolean-attributes-no-value.ts
# Documentation: https://herb-tools.dev/linter/rules/html-boolean-attributes-no-value

module Herb
  module Lint
    module Rules
      module Html
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
        class BooleanAttributesNoValue < VisitorRule
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

          def self.safe_autofixable? #: bool
            true
          end

          # @rbs override
          def visit_html_attribute_node(node)
            name = attribute_name(node)

            if name && boolean_attribute?(name) && node.value
              add_offense_with_autofix(
                message: "Boolean attribute '#{name}' should not have a value",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            # Remove the value from the boolean attribute
            # This creates a new HTMLAttributeNode with no equals sign and no value
            # We create it directly because copy_html_attribute_node uses || which prevents setting to nil
            new_node = Herb::AST::HTMLAttributeNode.new(
              node.type,
              node.location,
              node.errors,
              node.name,
              nil, # equals - remove the = sign
              nil  # value - remove the value
            )
            replace_node(parse_result, node, new_node)
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
end
