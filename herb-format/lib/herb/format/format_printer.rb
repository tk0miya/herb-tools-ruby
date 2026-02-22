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
      include FormatHelpers

      VOID_ELEMENTS = %w[
        area base br col embed hr img input link meta param source track wbr
      ].freeze

      PRESERVED_ELEMENTS = %w[script style pre textarea].freeze

      attr_reader :indent_width #: Integer
      attr_reader :max_line_length #: Integer
      attr_reader :format_context #: Context
      attr_reader :indent_level #: Integer

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
      # @rbs @in_conditional_open_tag_context: bool
      # @rbs @current_attribute_name: String?
      # @rbs @element_formatting_analysis: Hash[Herb::AST::HTMLElementNode, ElementAnalysis]
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
        @in_conditional_open_tag_context = false
        @current_attribute_name = nil
        @element_formatting_analysis = {}
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
        write(render_attributes_inline(node))
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

      # Capture output to a temporary buffer.
      # Saves and restores @lines, @string_line_count, and @inline_mode around the block.
      # Used by ElementAnalyzer to render elements speculatively for length checks.
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

      private

      # Current indent string based on indent_level.
      #
      def indent #: String
        " " * (indent_level * indent_width)
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

      # Temporarily enable inline mode for the duration of the block.
      #
      # @rbs &block: () -> void
      def with_inline_mode(&) #: void
        previous = @inline_mode
        @inline_mode = true
        yield
      ensure
        @inline_mode = previous
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
          with_indent do
            node.body.each { visit(_1) }
          end
        end
      end

      # Generate indentation string for the current indent level.
      #
      # @rbs level: Integer
      def indent_string(level = indent_level) #: String
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

      # Render attributes inline (same line).
      # Returns a string like ' class="foo" id="bar"', or "" if no attributes.
      #
      # @rbs open_tag: Herb::AST::HTMLOpenTagNode
      def render_attributes_inline(open_tag) #: String
        attributes = open_tag.child_nodes.select { _1.is_a?(Herb::AST::HTMLAttributeNode) }
        return "" if attributes.empty?

        " #{attributes.map { render_attribute(_1) }.join(' ')}"
      end

      # Render attributes in multiline format (one attribute per line).
      # Outputs:
      #   <tag_name [herb:disable comments]
      #     attr1="val1"
      #     attr2="val2"
      #   > (or /> for void elements)
      #
      # @rbs tag_name: String
      # @rbs children: Array[Herb::AST::Node]
      # @rbs is_void: bool
      def render_multiline_attributes(tag_name, children, is_void) #: void # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        opening_line = "<#{tag_name}"

        herb_disable_comments = children.select { herb_disable_comment?(_1) }
        if herb_disable_comments.any?
          comment_output = capture do
            herb_disable_comments.each do |comment|
              with_inline_mode do
                push(" ")
                visit(comment)
              end
            end
          end
          opening_line += comment_output.join
        end

        push_with_indent(opening_line)

        with_indent do
          children.each do |child|
            if child.is_a?(Herb::AST::HTMLAttributeNode)
              push_with_indent(render_attribute(child))
            elsif !child.is_a?(Herb::AST::WhitespaceNode) && !herb_disable_comment?(child)
              visit(child)
            end
          end
        end

        push_with_indent(is_void ? "/>" : ">")
      end

      # Render a single attribute.
      # Returns a string like 'class="foo"' or 'disabled' (boolean attribute).
      #
      # @rbs attribute: Herb::AST::HTMLAttributeNode
      def render_attribute(attribute) #: String
        name = get_attribute_name(attribute)
        @current_attribute_name = name

        if attribute.value.nil?
          @current_attribute_name = nil
          return name
        end

        open_quote, close_quote = get_attribute_quotes(attribute.value)
        content = render_attribute_value_content(attribute.value)

        @current_attribute_name = nil

        return render_class_attribute(name, content, open_quote, close_quote) if name == "class"

        "#{name}=#{open_quote}#{content}#{close_quote}"
      end

      # Extract the attribute name as a string.
      #
      # @rbs attribute: Herb::AST::HTMLAttributeNode
      def get_attribute_name(attribute) #: String
        attribute.name.children.map do |child|
          child.is_a?(Herb::AST::LiteralNode) ? child.content : ::Herb::Printer::IdentityPrinter.print(child)
        end.join
      end

      # Return normalized quote pair (always double quotes).
      #
      # @rbs _attribute_value: Herb::AST::HTMLAttributeValueNode
      def get_attribute_quotes(_attribute_value) #: [String, String]
        ['"', '"']
      end

      # Render the content of an attribute value node.
      # Handles literal content and embedded ERB nodes.
      #
      # @rbs attribute_value: Herb::AST::HTMLAttributeValueNode
      def render_attribute_value_content(attribute_value) #: String
        attribute_value.children.map do |child|
          child.is_a?(Herb::AST::LiteralNode) ? child.content : ::Herb::Printer::IdentityPrinter.print(child)
        end.join
      end

      # Render the class attribute with optional multiline wrapping for long values.
      # Normalizes whitespace and wraps long class lists across multiple lines
      # when the attribute would exceed max_line_length.
      #
      # @rbs name: String
      # @rbs content: String
      # @rbs open_quote: String
      # @rbs close_quote: String
      def render_class_attribute(name, content, open_quote, close_quote) #: String # rubocop:disable Metrics/CyclomaticComplexity
        normalized_content = content.gsub(/[ \t\n\r]+/, " ").strip

        if content.include?("\n") && normalized_content.length > 80
          wrapped = wrap_class_by_newlines(content, name, open_quote, close_quote)
          return wrapped if wrapped
        end

        current_indent = indent_level * indent_width
        attribute_line = "#{name}=#{open_quote}#{normalized_content}#{close_quote}"

        if current_indent + attribute_line.length > max_line_length &&
           normalized_content.length > 60
          return "#{name}=#{open_quote}#{normalized_content}#{close_quote}" if normalized_content.include?("<%")

          wrapped = wrap_class_by_length(normalized_content, name, open_quote, close_quote, current_indent)
          return wrapped if wrapped
        end

        "#{name}=#{open_quote}#{normalized_content}#{close_quote}"
      end

      # Wrap class attribute by splitting on original newlines.
      #
      # @rbs content: String
      # @rbs name: String
      # @rbs open_quote: String
      # @rbs close_quote: String
      def wrap_class_by_newlines(content, name, open_quote, close_quote) #: String?
        lines = content.split(/\r?\n/).map(&:strip).reject(&:empty?)
        return unless lines.length > 1

        "#{name}=#{open_quote}#{format_multiline_attribute_value(lines)}#{close_quote}"
      end

      # Wrap class attribute by breaking long token sequences into lines.
      #
      # @rbs normalized_content: String
      # @rbs name: String
      # @rbs open_quote: String
      # @rbs close_quote: String
      # @rbs current_indent: Integer
      def wrap_class_by_length(normalized_content, name, open_quote, close_quote, current_indent) #: String?
        lines = break_tokens_into_lines(normalized_content.split, current_indent)
        return unless lines.length > 1

        "#{name}=#{open_quote}#{format_multiline_attribute_value(lines)}#{close_quote}"
      end

      # Break an array of tokens into lines that fit within max_line_length.
      #
      # @rbs tokens: Array[String]
      # @rbs indent: Integer
      def break_tokens_into_lines(tokens, indent) #: Array[String]
        lines = []
        current_line = []
        current_length = indent

        tokens.each do |token|
          test_length = current_length + token.length + 1

          if test_length > max_line_length && current_line.any?
            lines << current_line.join(" ")
            current_line = [token]
            current_length = indent + token.length
          else
            current_line << token
            current_length = test_length
          end
        end

        lines << current_line.join(" ") if current_line.any?

        lines
      end

      # Format an array of lines as a multiline attribute value.
      # Each line is indented with two spaces, and the result is wrapped
      # with leading and trailing newlines.
      #
      # @rbs lines: Array[String]
      def format_multiline_attribute_value(lines) #: String
        "\n#{lines.map { |line| "  #{line}" }.join("\n")}\n"
      end

      # -- ERB Tag Normalization --

      # Format ERB content by normalizing whitespace.
      # Adds a leading space and a trailing space (or newline for heredocs).
      # Returns empty string when content is blank.
      #
      # @rbs content: String
      def format_erb_content(content) #: String
        trimmed_content = content.strip

        # Heredoc support (TypeScript issue #476)
        suffix = trimmed_content.start_with?("<<") ? "\n" : " "

        trimmed_content.empty? ? "" : " #{trimmed_content}#{suffix}"
      end

      # Extract the string value from an optional token node.
      # Returns empty string when the token is absent.
      #
      # @rbs token: untyped
      def erb_token_value(token) #: String
        token ? token.value : ""
      end

      # Reconstruct an ERB node as a string.
      # When with_formatting is true, the content is normalized via format_erb_content.
      #
      # @rbs node: Herb::AST::ERBContentNode
      # @rbs with_formatting: bool
      def reconstruct_erb_node(node, with_formatting: true) #: String
        open = erb_token_value(node.tag_opening)
        close = erb_token_value(node.tag_closing)
        content = erb_token_value(node.content)

        inner = with_formatting ? format_erb_content(content) : content

        open + inner + close
      end

      # Print an ERB node to the output buffer.
      # In inline mode no indentation is added; otherwise the current indent is prepended.
      #
      # @rbs node: Herb::AST::ERBContentNode
      def print_erb_node(node) #: void
        indent_str = @inline_mode ? "" : indent
        erb_text = reconstruct_erb_node(node, with_formatting: true)

        push(indent_str + erb_text)
      end
    end
  end
end
