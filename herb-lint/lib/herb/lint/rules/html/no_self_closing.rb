# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-self-closing.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-self-closing

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow self-closing syntax (`<tag />`) in HTML for all elements.
        #   In HTML5, the trailing slash in a start tag is obsolete and has no effect. Non-void elements
        #   require explicit end tags, and void elements are self-contained without the slash.
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
          def self.description = "Disallow self-closing syntax (`<tag />`) in HTML for all elements." #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            if self_closing?(node)
              tag = tag_name(node)
              instead = void_element?(node) ? "<#{tag}>" : "<#{tag}></#{tag}>"
              add_offense_with_autofix(
                message: "Use `#{instead}` instead of self-closing `<#{tag} />` for HTML compatibility.",
                location: node.open_tag.location,
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

            if void_element?(node)
              replace_node(parse_result, open_tag, new_open_tag)
            else
              close_tag = build_close_tag(tag_name(node))
              new_node = copy_html_element_node(node, open_tag: new_open_tag, close_tag:)
              replace_node(parse_result, node, new_node)
            end
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
