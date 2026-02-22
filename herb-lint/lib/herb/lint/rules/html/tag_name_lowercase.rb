# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-tag-name-lowercase.ts
# Documentation: https://herb-tools.dev/linter/rules/html-tag-name-lowercase

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Enforce that all HTML tag names are written in lowercase.
        #
        # Good:
        #   <div class="container"></div>
        #
        #   <input type="text" name="username" autocomplete="off">
        #
        #   <span>Label</span>
        #
        # Bad:
        #   <DIV class="container"></DIV>
        #
        #   <Input type="text" name="username" autocomplete="off">
        #
        #   <Span>Label</Span>
        #
        class TagNameLowercase < VisitorRule
          def self.rule_name = "html-tag-name-lowercase" #: String
          def self.description = "Enforce lowercase tag names" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            check_open_tag(node)
            check_close_tag(node)
            super
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode | Herb::AST::HTMLCloseTagNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            case node
            when Herb::AST::HTMLOpenTagNode
              fix_open_tag(node, parse_result)
            when Herb::AST::HTMLCloseTagNode
              fix_close_tag(node, parse_result)
            else
              false
            end
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_open_tag(node) #: void
            tag = raw_tag_name(node)
            return unless tag
            return if lowercase?(tag)
            return unless node.open_tag

            add_offense_with_autofix(
              message: "Tag name '#{tag}' should be lowercase",
              location: node.tag_name.location,
              node: node.open_tag
            )
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_close_tag(node) #: void
            close_tag = node.close_tag
            return unless close_tag

            tag = close_tag.tag_name&.value
            return unless tag
            return if lowercase?(tag)

            add_offense_with_autofix(
              message: "Tag name '#{tag}' should be lowercase",
              location: close_tag.tag_name.location,
              node: close_tag
            )
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs parse_result: Herb::ParseResult
          def fix_open_tag(node, parse_result) #: bool
            tag_name = node.tag_name.value
            return false unless tag_name

            new_tag_name_token = copy_token(node.tag_name, content: tag_name.downcase)
            new_open_tag = copy_html_open_tag_node(node, tag_name: new_tag_name_token)
            replace_node(parse_result, node, new_open_tag)
          end

          # @rbs node: Herb::AST::HTMLCloseTagNode
          # @rbs parse_result: Herb::ParseResult
          def fix_close_tag(node, parse_result) #: bool
            tag_name = node.tag_name.value
            return false unless tag_name

            new_tag_name_token = copy_token(node.tag_name, content: tag_name.downcase)
            new_close_tag = copy_html_close_tag_node(node, tag_name: new_tag_name_token)
            replace_node(parse_result, node, new_close_tag)
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
