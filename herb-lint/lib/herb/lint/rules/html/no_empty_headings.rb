# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-empty-headings.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-empty-headings

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows empty heading elements.
        #
        # Heading elements (`<h1>`-`<h6>`) must contain meaningful content
        # and should not be empty or contain only whitespace.
        #
        # Good:
        #   <h1>Page Title</h1>
        #   <h2><%= title %></h2>
        #
        # Bad:
        #   <h1></h1>
        #   <h2>   </h2>
        class NoEmptyHeadings < VisitorRule
          HEADING_TAGS = %w[h1 h2 h3 h4 h5 h6].freeze #: Array[String]

          def self.rule_name #: String
            "html-no-empty-headings"
          end

          def self.description #: String
            "Heading elements must not be empty"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # @rbs override
          def visit_html_element_node(node)
            if heading?(node) && empty_content?(node)
              add_offense(
                message: "Heading element `<#{raw_tag_name(node)}>` must not be empty",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def heading?(node) #: bool
            HEADING_TAGS.include?(tag_name(node))
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def empty_content?(node) #: bool
            return true if node.body.empty?

            node.body.all? do |child|
              child.is_a?(Herb::AST::HTMLTextNode) && child.content.strip.empty?
            end
          end
        end
      end
    end
  end
end
