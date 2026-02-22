# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-empty-headings.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-empty-headings

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow headings (`h1`, `h2`, etc.) with no accessible text content.
        #
        # Good:
        #   <h1>Heading Content</h1>
        #
        #   <h1><span>Text</span></h1>
        #
        #   <div role="heading" aria-level="1">Heading Content</div>
        #
        #   <h1 aria-hidden="true">Heading Content</h1>
        #
        #   <h1 hidden>Heading Content</h1>
        #
        # Bad:
        #   <h1></h1>
        #
        #   <h2></h2>
        #
        #   <h3></h3>
        #
        #   <h4></h4>
        #
        #   <h5></h5>
        #
        #   <h6></h6>
        #
        #   <div role="heading" aria-level="1"></div>
        #
        #   <h1><span aria-hidden="true">Inaccessible text</span></h1>
        #
        class NoEmptyHeadings < VisitorRule
          HEADING_TAGS = %w[h1 h2 h3 h4 h5 h6].freeze #: Array[String]

          def self.rule_name = "html-no-empty-headings" #: String
          def self.description = "Heading elements must not be empty" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

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
