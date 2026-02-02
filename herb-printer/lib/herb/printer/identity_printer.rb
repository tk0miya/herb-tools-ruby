# frozen_string_literal: true

module Herb
  module Printer
    # Lossless round-trip printer that reconstructs the original source code
    # exactly from an AST produced by Herb.parse.
    class IdentityPrinter < Base
      # -- Leaf nodes --

      # @rbs override
      def visit_literal_node(node)
        write(node.content)
      end

      # @rbs override
      def visit_html_text_node(node)
        write(node.content)
      end

      # @rbs override
      def visit_whitespace_node(node)
        write(node.value.value) if node.value
      end

      # -- HTML attribute nodes --

      # @rbs override
      def visit_html_attribute_node(node)
        visit(node.name)
        write(node.equals.value) if node.equals
        visit(node.value) if node.value
      end

      # @rbs override
      def visit_html_attribute_name_node(node)
        visit_child_nodes(node)
      end

      # @rbs override
      def visit_html_attribute_value_node(node)
        write(node.open_quote.value) if node.open_quote
        super
        write(node.close_quote.value) if node.close_quote
      end

      # -- HTML comment, doctype, XML declaration, CDATA --

      # @rbs override
      def visit_html_comment_node(node)
        write(node.comment_start.value)
        super
        write(node.comment_end.value)
      end

      # @rbs override
      def visit_html_doctype_node(node)
        write(node.tag_opening.value)
        super
        write(node.tag_closing.value)
      end

      # @rbs override
      def visit_xml_declaration_node(node)
        write(node.tag_opening.value)
        super
        write(node.tag_closing.value)
      end

      # @rbs override
      def visit_cdata_node(node)
        write(node.tag_opening.value)
        super
        write(node.tag_closing.value)
      end

      # -- HTML structure nodes --

      # @rbs override
      def visit_html_element_node(node)
        context.enter_tag(node.tag_name&.value || "")
        super
        context.exit_tag
      end

      # @rbs override
      def visit_html_open_tag_node(node)
        write(node.tag_opening.value)
        write(node.tag_name.value)
        super
        write(node.tag_closing.value)
      end

      # Unlike open tags, close tags can have WhitespaceNode children on both
      # sides of tag_name (e.g. `</ div >`). Since tag_name is a Token and not
      # part of child_nodes, we must split children around its position rather
      # than using super, which would place all children after the tag name.
      #
      # @rbs override
      def visit_html_close_tag_node(node)
        write(node.tag_opening.value)
        visit_all(nodes_before_token(node.children, node.tag_name))
        write(node.tag_name.value)
        visit_all(nodes_after_token(node.children, node.tag_name))
        write(node.tag_closing.value)
      end

      private

      # Return child nodes that end at or before the token's start position.
      #
      # @rbs children: Array[Herb::AST::Node]
      # @rbs token: Herb::Token
      def nodes_before_token(children, token) #: Array[Herb::AST::Node]
        token_start = token.location.start

        children.select do |child|
          child_end = child.location.end

          child_end.line < token_start.line ||
            (child_end.line == token_start.line && child_end.column <= token_start.column)
        end
      end

      # Return child nodes that start at or after the token's end position.
      #
      # @rbs children: Array[Herb::AST::Node]
      # @rbs token: Herb::Token
      def nodes_after_token(children, token) #: Array[Herb::AST::Node]
        token_end = token.location.end

        children.select do |child|
          child_start = child.location.start

          child_start.line > token_end.line ||
            (child_start.line == token_end.line && child_start.column >= token_end.column)
        end
      end
    end
  end
end
