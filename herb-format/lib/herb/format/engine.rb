# frozen_string_literal: true

module Herb
  module Format
    # Core formatting engine that traverses AST and applies formatting rules.
    #
    # Uses a visitor pattern with dynamic dispatch to handle different node types.
    # Each node type is handled by a visit_<node_type> method.
    #
    # @rbs indent_width: Integer
    # @rbs max_line_length: Integer
    # @rbs @context: Context
    # @rbs @output: String
    class Engine # rubocop:disable Metrics/ClassLength
      VOID_ELEMENTS = %w[
        area base br col embed hr img input link meta param source track wbr
      ].freeze

      PRESERVED_ELEMENTS = %w[pre code script style].freeze

      attr_reader :indent_width #: Integer
      attr_reader :max_line_length #: Integer

      # @rbs indent_width: Integer
      # @rbs max_line_length: Integer
      def initialize(indent_width:, max_line_length:) #: void
        @indent_width = indent_width
        @max_line_length = max_line_length
      end

      # Format AST and return formatted string.
      #
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs context: Context
      def format(ast, context) #: String
        @context = context
        @output = String.new
        visit(ast, depth: 0)
        @output
      end

      private

      # Visit a node using dynamic dispatch to the appropriate visit_* method.
      #
      # This implements the visitor pattern by dispatching to visit_<node_type> methods.
      # If no specific handler exists, falls back to visit_unknown.
      #
      # @rbs node: Herb::AST::Node
      # @rbs depth: Integer
      def visit(node, depth:) #: void
        # Normalize node type from "AST_DOCUMENT_NODE" to :document
        normalized_type = normalize_node_type(node.type)
        method_name = :"visit_#{normalized_type}"

        if respond_to?(method_name, true)
          send(method_name, node, depth)
        else
          visit_unknown(node, depth)
        end
      end

      # Fallback handler for unknown node types.
      # Uses IdentityPrinter to preserve the original source.
      #
      # @rbs node: Herb::AST::Node
      # @rbs _depth: Integer
      def visit_unknown(node, _depth) #: void
        @output << Herb::Printer::IdentityPrinter.print(node)
      end

      # Normalize node type from AST constant format to symbol format.
      # "AST_DOCUMENT_NODE" => :document
      # "AST_HTML_ELEMENT_NODE" => :html_element
      # :unknown_type => :unknown_type (already a symbol, pass through)
      #
      # @rbs type: String | Symbol
      def normalize_node_type(type) #: Symbol
        # If already a symbol, return as-is
        return type if type.is_a?(Symbol)

        type
          .sub(/^AST_/, "")           # Remove AST_ prefix
          .sub(/_NODE$/, "")          # Remove _NODE suffix
          .downcase                   # Convert to lowercase
          .to_sym                     # Convert to symbol
      end

      # Generate indentation string for the given depth.
      #
      # @rbs depth: Integer
      def indent(depth) #: String
        " " * (indent_width * depth)
      end

      # Check if tag is a void element (self-closing, no closing tag).
      #
      # @rbs tag_name: String
      def void_element?(tag_name) #: bool
        VOID_ELEMENTS.include?(tag_name.downcase)
      end

      # Check if tag content should be preserved (not reformatted).
      #
      # @rbs tag_name: String
      def preserved_element?(tag_name) #: bool
        PRESERVED_ELEMENTS.include?(tag_name.downcase)
      end

      # Visit document node (root of AST).
      #
      # @rbs node: Herb::AST::DocumentNode
      # @rbs depth: Integer
      def visit_document(node, depth) #: void
        node.child_nodes.each do |child|
          visit(child, depth:)
        end
      end

      # Visit HTML text node.
      #
      # @rbs node: Herb::AST::HTMLTextNode
      # @rbs _depth: Integer
      def visit_html_text(node, _depth) #: void
        # Preserve text content as-is
        @output << node.content
      end

      # Visit whitespace node.
      #
      # @rbs node: Herb::AST::WhitespaceNode
      # @rbs _depth: Integer
      def visit_whitespace(node, _depth) #: void
        # Preserve whitespace as-is for now
        # (Future: normalize whitespace based on context)
        @output << node.value.value
      end

      # Visit literal node.
      #
      # @rbs node: Herb::AST::LiteralNode
      # @rbs _depth: Integer
      def visit_literal(node, _depth) #: void
        @output << node.content
      end

      # Visit HTML element node.
      #
      # @rbs node: Herb::AST::HTMLElementNode
      # @rbs depth: Integer
      def visit_html_element(node, depth) #: void # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        tag_name = node.tag_name&.value || ""
        preserved = preserved_element?(tag_name)

        # Format opening tag
        visit(node.open_tag, depth:)

        # Format body (skip if void element)
        return if void_element?(tag_name)

        if preserved
          # Preserve content as-is for <pre>, <code>, etc.
          node.body.each do |child|
            @output << Herb::Printer::IdentityPrinter.print(child)
          end
        else
          # Format body with increased depth
          node.body.each do |child|
            visit(child, depth: depth + 1)
          end
        end

        # Format closing tag
        visit(node.close_tag, depth:) if node.close_tag
      end

      # Visit HTML open tag node.
      #
      # @rbs node: Herb::AST::HTMLOpenTagNode
      # @rbs depth: Integer
      def visit_html_open_tag(node, depth) #: void
        @output << indent(depth) if should_indent?(node)
        @output << "<"
        @output << node.tag_name.value if node.tag_name

        # Visit child nodes (which include whitespace and attributes)
        node.child_nodes.each do |child|
          if normalize_node_type(child.type) == :whitespace
            # Output single space for attributes
            @output << " " if @output[-1] != "<"
          else
            visit(child, depth:)
          end
        end

        @output << ">"
      end

      # Visit HTML close tag node.
      #
      # @rbs node: Herb::AST::HTMLCloseTagNode
      # @rbs depth: Integer
      def visit_html_close_tag(node, depth) #: void
        @output << indent(depth) if should_indent?(node)
        @output << "</"
        @output << node.tag_name.value if node.tag_name
        @output << ">"
      end

      # Determine if node should be indented.
      #
      # @rbs node: Herb::AST::Node
      def should_indent?(_node) #: bool
        # For now, always indent tags
        # Future: track context like "previous was newline"
        true
      end

      # Visit HTML attribute node.
      #
      # @rbs node: Herb::AST::HTMLAttributeNode
      # @rbs depth: Integer
      def visit_html_attribute(node, depth) #: void
        # Visit attribute name
        visit(node.name, depth:) if node.name

        # Visit equals and value if present
        return unless node.value

        @output << "="
        visit(node.value, depth:)
      end

      # Visit HTML attribute name node.
      #
      # @rbs node: Herb::AST::HTMLAttributeNameNode
      # @rbs depth: Integer
      def visit_html_attribute_name(node, depth) #: void
        node.child_nodes.each do |child|
          visit(child, depth:)
        end
      end

      # Visit HTML attribute value node.
      #
      # @rbs node: Herb::AST::HTMLAttributeValueNode
      # @rbs depth: Integer
      def visit_html_attribute_value(node, depth) #: void
        # Always use double quotes
        @output << '"'

        node.child_nodes.each do |child|
          visit(child, depth:)
        end

        @output << '"'
      end
    end
  end
end
