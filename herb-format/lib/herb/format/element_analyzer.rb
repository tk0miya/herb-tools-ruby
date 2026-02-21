# frozen_string_literal: true

module Herb
  module Format
    # Analyzes HTMLElementNode to determine formatting decisions.
    #
    # Determines whether the open tag, element content, and close tag
    # should be rendered inline or as block-level content.
    class ElementAnalyzer
      include FormatHelpers

      # @rbs @printer: FormatPrinter
      # @rbs @max_line_length: Integer
      # @rbs @indent_width: Integer
      # @rbs @in_conditional_open_tag_context: bool

      # @rbs printer: FormatPrinter
      # @rbs max_line_length: Integer
      # @rbs indent_width: Integer
      def initialize(printer, max_line_length, indent_width) #: void
        @printer = printer
        @max_line_length = max_line_length
        @indent_width = indent_width
        @in_conditional_open_tag_context = false
      end

      # Should render open tag inline?
      #
      # @rbs element: Herb::AST::HTMLElementNode
      def should_render_open_tag_inline?(element) #: bool
        # Conditional tag → false
        return false if @in_conditional_open_tag_context

        # Complex ERB → false
        inline_nodes = get_inline_nodes(element.open_tag)
        return false if complex_erb_control_flow?(inline_nodes)

        # Multiline attributes → false
        return false if multiline_attributes?(element.open_tag)

        # Check attribute count and line length
        should_render_inline?(element)
      end

      private

      # Get inline nodes from open tag (excludes whitespace and attributes).
      #
      # @rbs open_tag: Herb::AST::HTMLOpenTagNode
      def get_inline_nodes(open_tag) #: Array[Herb::AST::Node]
        open_tag.child_nodes.reject do |child|
          child.is_a?(Herb::AST::WhitespaceNode) ||
            child.is_a?(Herb::AST::HTMLAttributeNode)
        end
      end

      # Has multiline attributes?
      #
      # @rbs open_tag: Herb::AST::HTMLOpenTagNode
      def multiline_attributes?(open_tag) #: bool # rubocop:disable Lint/UnusedMethodArgument
        # TODO: Implementation (check if attribute values contain \n)
        false
      end

      # Should render inline? Check attribute count and line length.
      #
      # @rbs element: Herb::AST::HTMLElementNode
      def should_render_inline?(element) #: bool # rubocop:disable Lint/UnusedMethodArgument
        # TODO: Implement proper attribute count and line length check
        # (requires accessible capture method on printer)
        true
      end
    end
  end
end
