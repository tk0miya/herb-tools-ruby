# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-self-closing.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-self-closing

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow self-closing syntax (`<tag />`) in HTML for all elements.
        #
        #   In HTML5, the trailing slash in a start tag is obsolete and has no effect.
        #   Non-void elements require explicit end tags, and void elements are
        #   self-contained without the slash.
        #
        # Good:
        #   <span></span>
        #   <div></div>
        #   <section></section>
        #   <custom-element></custom-element>
        #
        #   <img src="/logo.png" alt="Logo">
        #   <input type="text" autocomplete="off">
        #   <br>
        #   <hr>
        #
        # Bad:
        #   <span />
        #
        #   <div />
        #
        #   <section />
        #
        #   <custom-element />
        #
        #   <img src="/logo.png" alt="Logo" />
        #
        #   <input type="text" autocomplete="off" />
        #
        #   <br />
        #
        #   <hr />
        #
        class NoSelfClosing < VisitorRule
          VOID_ELEMENTS = %w[
            area
            base
            br
            col
            embed
            hr
            img
            input
            link
            meta
            param
            source
            track
            wbr
          ].freeze #: Array[String]

          def self.rule_name = "html-no-self-closing" #: String
          def self.description = "Disallow self-closing syntax for HTML elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if self_closing?(node)
              name = tag_name(node)
              message = if void_element?(node)
                          "Use `<#{name}>` instead of self-closing `<#{name} />` for HTML compatibility."
                        else
                          "Use `<#{name}></#{name}>` instead of self-closing `<#{name} />` for HTML compatibility."
                        end
              add_offense_with_autofix(
                message:,
                location: node.open_tag.tag_closing.location,
                node:
              )
            end
            super
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            open_tag = node.open_tag
            tag_closing = copy_token(open_tag.tag_closing, content: ">")
            children = open_tag.children.dup
            children.pop if children.last.is_a?(Herb::AST::WhitespaceNode)
            new_open_tag = copy_html_open_tag_node(open_tag, tag_closing:, children:)
            replace_node(parse_result, open_tag, new_open_tag)
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def void_element?(node) #: bool
            name = tag_name(node)
            return false if name.nil?

            VOID_ELEMENTS.include?(name.downcase)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def self_closing?(node) #: bool
            return false unless node.open_tag

            node.open_tag.tag_closing&.value == "/>"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def tag_name(node) #: String?
            node.open_tag&.tag_name&.value
          end
        end
      end
    end
  end
end
