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

      # Analyze element and return formatting decisions.
      #
      # @rbs element: Herb::AST::HTMLElementNode
      def analyze(element) #: ElementAnalysis
        tag_name = get_tag_name(element)

        if content_preserving?(tag_name)
          ElementAnalysis.new(open_tag_inline: false, element_content_inline: false, close_tag_inline: false)
        elsif element.is_void
          ElementAnalysis.new(open_tag_inline: true, element_content_inline: true, close_tag_inline: true)
        else
          open_tag_inline = should_render_open_tag_inline?(element)
          element_content_inline = should_render_element_content_inline?(element, open_tag_inline)
          close_tag_inline = should_render_close_tag_inline?(element, element_content_inline)

          ElementAnalysis.new(
            open_tag_inline:,
            element_content_inline:,
            close_tag_inline:
          )
        end
      end

      private

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

      # Should render element content inline?
      #
      # Determines whether the children of an element should be rendered on the
      # same line as the opening tag. Returns false immediately if the open tag
      # itself is not inline. For inline elements, renders the full element via
      # capture to check the total line length.
      #
      # @rbs element: Herb::AST::HTMLElementNode
      # @rbs open_tag_inline: bool
      def should_render_element_content_inline?(element, open_tag_inline) #: bool # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # Open tag not inline → false
        return false unless open_tag_inline

        # No children → true
        return true if element.body.empty?

        # Has non-inline child → false
        has_non_inline_child = element.body.any? { |child| !inline_node?(child) }
        return false if has_non_inline_child

        tag_name = get_tag_name(element)

        # Inline element: render entire element and check length
        if inline_element?(tag_name)
          rendered = @printer.capture { @printer.visit(element) }
          total_length = rendered.join.length
          return total_length <= @max_line_length
        end

        # Block element: check significant children
        significant_children = filter_significant_children(element.body)

        # Single text child with no newlines → true
        if significant_children.length == 1 &&
           significant_children[0].is_a?(Herb::AST::HTMLTextNode)
          return !significant_children[0].content.include?("\n")
        end

        # All nested elements are inline → true
        return true if all_nested_elements_inline?(significant_children)

        # Mixed text and inline content → true
        return true if mixed_text_and_inline_content?(significant_children)

        false
      end

      # Should render close tag inline?
      #
      # @rbs _element: Herb::AST::HTMLElementNode
      # @rbs element_content_inline: bool
      def should_render_close_tag_inline?(_element, element_content_inline) #: bool
        element_content_inline
      end

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

      # Should render inline? Check attribute count and open tag line length.
      # Elements with 0-1 attributes always render inline (single-attribute
      # class value wrapping is handled separately by render_class_attribute).
      # Elements with 2+ attributes use a line-length check on the open tag.
      #
      # @rbs element: Herb::AST::HTMLElementNode
      def should_render_inline?(element) #: bool
        attributes = element.open_tag.child_nodes.select { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
        return true if attributes.length <= 1

        tag_name = get_tag_name(element)
        inline_attrs = @printer.send(:render_attributes_inline, element.open_tag)
        indent_offset = @printer.indent_level * @printer.indent_width
        open_tag_length = tag_name.length + inline_attrs.length + 1 # +1 for ">"
        indent_offset + open_tag_length <= @max_line_length
      end

      # Is this node inline (can appear on the same line as surrounding content)?
      #
      # @rbs node: Herb::AST::Node
      def inline_node?(node) #: bool
        return true if node.is_a?(Herb::AST::WhitespaceNode)
        return true if node.is_a?(Herb::AST::HTMLTextNode)

        if node.is_a?(Herb::AST::HTMLElementNode)
          tag_name = get_tag_name(node)
          return inline_element?(tag_name)
        end

        return !erb_control_flow_node?(node) if erb_node?(node)

        false
      end
    end
  end
end
