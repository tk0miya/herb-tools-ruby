# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-tag-name-lowercase.ts
# Documentation: https://herb-tools.dev/linter/rules/html-tag-name-lowercase

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
        class TagNameLowercase < VisitorRule
          def self.rule_name #: String
            "html-tag-name-lowercase"
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
            tag = raw_tag_name(node)
            return unless tag
            return if lowercase?(tag)

            add_offense(
              message: "Tag name '#{tag}' should be lowercase",
              location: node.tag_name.location
            )
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_close_tag(node) #: void
            close_tag = node.close_tag
            return unless close_tag

            tag = close_tag.tag_name&.value
            return unless tag
            return if lowercase?(tag)

            add_offense(
              message: "Tag name '#{tag}' should be lowercase",
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
