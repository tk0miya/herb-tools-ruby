# frozen_string_literal: true

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

          # @rbs override
          def visit_html_element_node(node)
            check_duplicate_attributes(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_attributes(node) #: void
            return unless node.open_tag

            seen_attributes = {} #: Hash[String, Herb::Location]

            node.open_tag.children.each do |child|
              next unless child.is_a?(Herb::AST::HTMLAttributeNode)

              name = attribute_name(child)
              next if name.nil?

              normalized_name = name.downcase
              if seen_attributes.key?(normalized_name)
                add_offense(
                  message: "Duplicate attribute '#{name}'",
                  location: child.location
                )
              else
                seen_attributes[normalized_name] = child.location
              end
            end
          end
        end
      end
    end
  end
end
