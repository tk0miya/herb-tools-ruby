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
            return if tag_name(node) == "template"

            if heading?(node) && empty_heading?(node)
              element_description =
                if standard_heading?(node)
                  "`<#{raw_tag_name(node)}>`"
                else
                  "`<#{raw_tag_name(node)} role=\"heading\">`"
                end

              message = "Heading element #{element_description} must not be empty. " \
                        "Provide accessible text content for screen readers and SEO."
              add_offense(message:, location: node.location)
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def heading?(node) #: bool
            standard_heading?(node) || aria_heading?(node)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def standard_heading?(node) #: bool
            HEADING_TAGS.include?(tag_name(node))
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def aria_heading?(node) #: bool
            attribute_value(find_attribute(node, "role"))&.downcase == "heading"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def empty_heading?(node) #: bool
            return true if node.body.nil? || node.body.empty?

            !accessible_content?(node.body)
          end

          # @rbs nodes: Array[untyped]
          def accessible_content?(nodes) #: bool
            nodes.any? do |child|
              case child
              when Herb::AST::HTMLTextNode, Herb::AST::LiteralNode
                !child.content.strip.empty?
              when Herb::AST::HTMLElementNode
                element_accessible?(child)
              when Herb::AST::ERBContentNode
                child.tag_opening.value.start_with?("<%=")
              else
                false
              end
            end
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def element_accessible?(node) #: bool
            aria_hidden = attribute_value(find_attribute(node, "aria-hidden"))
            return false if aria_hidden == "true"
            return false if node.body.nil? || node.body.empty?

            accessible_content?(node.body)
          end
        end
      end
    end
  end
end
