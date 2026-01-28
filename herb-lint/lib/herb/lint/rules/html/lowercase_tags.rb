# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that enforces lowercase tag names.
        #
        # HTML tag names are case-insensitive, but lowercase is the standard
        # convention for modern HTML. This rule ensures consistency.
        #
        # Good:
        #   <div></div>
        #   <span>text</span>
        #
        # Bad:
        #   <DIV></DIV>
        #   <Span>text</Span>
        class LowercaseTags < VisitorRule
          def self.rule_name #: String
            "html/lowercase-tags"
          end

          def self.description #: String
            "Enforce lowercase tag names"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            check_open_tag(node)
            check_close_tag(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_open_tag(node) #: void
            tag_name = node.tag_name&.value
            return unless tag_name
            return if lowercase?(tag_name)

            add_offense(
              message: "Tag name '#{tag_name}' should be lowercase",
              location: node.tag_name.location
            )
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_close_tag(node) #: void
            close_tag = node.close_tag
            return unless close_tag

            close_tag_name = close_tag.tag_name&.value
            return unless close_tag_name
            return if lowercase?(close_tag_name)

            add_offense(
              message: "Tag name '#{close_tag_name}' should be lowercase",
              location: close_tag.tag_name.location
            )
          end

          # @rbs str: String
          def lowercase?(str) #: bool
            str == str.downcase
          end
        end
      end
    end
  end
end
