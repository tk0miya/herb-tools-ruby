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
    class FormatPrinter < ::Herb::Printer::Base # rubocop:disable Metrics/ClassLength
      VOID_ELEMENTS = %w[
        area base br col embed hr img input link meta param source track wbr
      ].freeze

      PRESERVED_ELEMENTS = %w[script style pre textarea].freeze

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

      # @rbs @lines: Array[String]
      # @rbs @indent_level: Integer
      # @rbs @string_line_count: Integer
      # @rbs @inline_mode: bool
      # @rbs @node_is_multiline: Hash[Herb::AST::Node, bool]

      # @rbs indent_width: Integer
      # @rbs max_line_length: Integer
      # @rbs format_context: Context
      def initialize(indent_width:, max_line_length:, format_context:) #: void
        super()
        @indent_width = indent_width
        @max_line_length = max_line_length
        @format_context = format_context
        @lines = []
        @indent_level = 0
        @string_line_count = 0
        @inline_mode = false
        @node_is_multiline = {}
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

      # -- HTML element nodes --

      # Visit HTML element node. Handles void elements (no close tag) and
      # preserved elements (content unchanged) specially.
      #
      # @rbs override
      def visit_html_element_node(node)
        tag_name = node.tag_name&.value || ""

        context.enter_tag(tag_name) do
          visit(node.open_tag)

          unless node.is_void
            visit_element_body(node)
            visit(node.close_tag) if node.close_tag
          end
        end
      end

      # Visit HTML open tag node.
      # Outputs the opening tag structure: <tag_name attributes>
      #
      # @rbs override
      def visit_html_open_tag_node(node)
        write(node.tag_opening.value)
        write(node.tag_name.value)
        visit_child_nodes(node)
        write(node.tag_closing.value)
      end

      # Visit HTML close tag node.
      # Outputs the closing tag structure: </tag_name>
      #
      # @rbs override
      def visit_html_close_tag_node(node)
        write(node.tag_opening.value)
        write(node.tag_name.value) if node.tag_name
        write(node.tag_closing.value)
      end

      private

      # Current indent string based on @indent_level.
      #
      def indent #: String
        " " * (@indent_level * @indent_width)
      end

      # Push line with indentation applied.
      # Empty or whitespace-only lines are pushed without indentation.
      #
      # @rbs line: String
      def push_with_indent(line) #: void
        indent_str = line.strip.empty? ? "" : indent
        push(indent_str + line)
      end

      # Append text to the last line in the buffer (no newline).
      # If buffer is empty, starts a new line.
      #
      # @rbs text: String
      def push_to_last_line(text) #: void
        if @lines.empty?
          @lines << text
        else
          @lines[-1] += text
        end
      end

      # Push a line to the output buffer.
      #
      # @rbs line: String
      def push(line) #: void
        @lines << line
        @string_line_count += line.count("\n")
      end

      # Capture output to a temporary buffer.
      # Saves and restores @lines, @string_line_count, and @inline_mode around the block.
      #
      # @rbs &block: () -> void
      def capture(&) #: Array[String]
        previous_lines = @lines
        previous_string_line_count = @string_line_count
        previous_inline_mode = @inline_mode

        @lines = []
        @string_line_count = 0

        yield

        result = @lines
        @lines = previous_lines
        @string_line_count = previous_string_line_count
        @inline_mode = previous_inline_mode

        result
      end

      # Track if a node spans multiple lines.
      # Records whether the node produced multiline output.
      #
      # @rbs node: Herb::AST::Node
      # @rbs &block: () -> void
      def track_boundary(node, &) #: void
        start_line_count = @string_line_count

        yield

        end_line_count = @string_line_count

        @node_is_multiline[node] = true if end_line_count > start_line_count
      end

      # Temporarily increase indent level for the duration of the block.
      #
      # @rbs &block: () -> void
      def with_indent(&) #: void
        @indent_level += 1
        yield
        @indent_level -= 1
      end

      # Visit the body of an HTML element. For preserved elements (script,
      # style, pre, textarea), content is output as-is using IdentityPrinter.
      # For normal elements, content is formatted with increased indentation.
      #
      # @rbs node: Herb::AST::HTMLElementNode
      def visit_element_body(node) #: void
        tag_name = node.tag_name&.value || ""

        if preserved_element?(tag_name)
          # Preserve content as-is for script, style, pre, textarea
          node.body.each do |child|
            write(::Herb::Printer::IdentityPrinter.print(child))
          end
        else
          # Format body with increased indent
          context.indent do
            node.body.each { visit(_1) }
          end
        end
      end

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
