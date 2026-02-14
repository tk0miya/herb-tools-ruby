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
    class Engine
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
    end
  end
end
