# frozen_string_literal: true

module Herb
  module Format
    # Core formatting printer that traverses AST and produces formatted output.
    #
    # Extends Printer::Base (which extends Herb::Visitor) to leverage the
    # standard visitor pattern with double-dispatch via node.accept(self).
    # This mirrors the TypeScript FormatPrinter extends Printer extends Visitor
    # architecture.
    #
    # Leaf nodes are handled with identity-like output for now. As formatting
    # rules are added, visitor methods will be overridden to apply indentation,
    # line wrapping, attribute formatting, and other transformations.
    class FormatPrinter < ::Herb::Printer::Base
      VOID_ELEMENTS = %w[
        area base br col embed hr img input link meta param source track wbr
      ].freeze

      PRESERVED_ELEMENTS = %w[pre code script style].freeze

      attr_reader :indent_width #: Integer
      attr_reader :max_line_length #: Integer
      attr_reader :format_context #: Context

      # Format the given input and return a formatted string.
      #
      # @rbs input: Herb::ParseResult | Herb::AST::Node
      # @rbs format_context: Context
      # @rbs ignore_errors: bool
      def self.format(input, format_context:, ignore_errors: false) #: String
        node = input.is_a?(::Herb::ParseResult) ? input.value : input
        validate_no_errors!(node) unless ignore_errors

        printer = new(
          indent_width: format_context.indent_width,
          max_line_length: format_context.max_line_length,
          format_context:
        )
        printer.visit(node)
        printer.context.output
      end

      # @rbs indent_width: Integer
      # @rbs max_line_length: Integer
      # @rbs format_context: Context
      def initialize(indent_width:, max_line_length:, format_context:) #: void
        super()
        @indent_width = indent_width
        @max_line_length = max_line_length
        @format_context = format_context
      end

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

      private

      # Generate indentation string for the current indent level.
      #
      # @rbs level: Integer
      def indent_string(level = context.current_indent_level) #: String
        " " * (indent_width * level)
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
