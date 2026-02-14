# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-boolean-attributes-no-value.ts
# Documentation: https://herb-tools.dev/linter/rules/html-boolean-attributes-no-value

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Omit attribute values for boolean HTML attributes. For boolean attributes, their presence alone
        #   represents true, and their absence represents false. There is no need to assign a value or use quotes.
        #
        # Good:
        #   <input type="checkbox" checked>
        #
        #   <button disabled>Submit</button>
        #
        #   <select multiple></select>
        #
        # Bad:
        #   <input type="checkbox" checked="checked">
        #
        #   <button disabled="true">Submit</button>
        #
        #   <select multiple="multiple"></select>
        #
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

          def self.rule_name = "html-boolean-attributes-no-value" #: String
          def self.description = "Boolean attributes should not have values" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            name = attribute_name(node)

            if name && boolean_attribute?(name) && node.value
              # Build the full attribute string for the error message
              value = attribute_value(node)
              full_attribute = "#{name}=\"#{value}\""

              add_offense_with_autofix(
                message: "Boolean attribute `#{name}` should not have a value. " \
                         "Use `#{name.downcase}` instead of `#{full_attribute}`.",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs node: Herb::AST::HTMLAttributeNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
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
