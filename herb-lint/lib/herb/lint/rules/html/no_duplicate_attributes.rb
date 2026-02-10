# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-attributes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-attributes

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows duplicate attributes on the same element.
        #
        # HTML elements should not have multiple attributes with the same name.
        # Duplicate attributes can cause unexpected behavior as browsers only
        # use the first occurrence.
        #
        # Good:
        #   <div class="foo bar">content</div>
        #
        # Bad:
        #   <div class="foo" class="bar">content</div>
        class NoDuplicateAttributes < VisitorRule
          def self.rule_name #: String
            "html-no-duplicate-attributes"
          end

          def self.description #: String
            "Disallow duplicate attributes on the same element"
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # @rbs override
          def visit_html_element_node(node)
            check_duplicate_attributes(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_attributes(node) #: void
            seen_attributes = {} #: Hash[String, Herb::Location]

            attributes(node).each do |attr|
              name = attribute_name(attr)
              next if name.nil?

              normalized_name = name.downcase
              if seen_attributes.key?(normalized_name)
                add_offense(
                  message: "Duplicate attribute '#{name}'",
                  location: attr.location
                )
              else
                seen_attributes[normalized_name] = attr.location
              end
            end
          end
        end
      end
    end
  end
end
