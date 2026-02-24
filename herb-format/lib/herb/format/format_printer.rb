# frozen_string_literal: true

require_relative "context"
require_relative "element_analysis"
require_relative "element_analyzer"
require_relative "format_helpers"

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
        printer.formatted_output
      end

      # @rbs @lines: Array[String]
      # @rbs @string_line_count: Integer
      # @rbs @inline_mode: bool
      # @rbs @in_conditional_open_tag_context: bool
      # @rbs @current_attribute_name: String?
      # @rbs @element_stack: Array[Herb::AST::HTMLElementNode]
      # @rbs @element_formatting_analysis: Hash[Herb::AST::HTMLElementNode, ElementAnalysis?]
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
        @element_stack = []
        @element_formatting_analysis = {}
        @node_is_multiline = {}
      end

      # -- Leaf nodes --

      # @rbs override
      def visit_literal_node(node)
        push_to_last_line(node.content)
      end

      # @rbs override
      def visit_html_text_node(node)
        push_to_last_line(node.content)
      end

      # @rbs override
      def visit_whitespace_node(node)
        push_to_last_line(node.value.value) if node.value
      end

      # -- HTML element nodes --

      # Visit HTML element node.
      # Pushes/pops @element_stack around child visiting so that open and close
      # tag visitors can access the enclosing element via current_element.
      # Pre-computes ElementAnalysis for non-preserved elements.
      #
      # @rbs override
      def visit_html_element_node(node) # rubocop:disable Metrics/AbcSize
        tag_name = node.tag_name&.value || ""

        @element_stack.push(node)

        context.enter_tag(tag_name) do
          # Pre-compute analysis for non-preserved elements.
          # Use key? guard to break infinite recursion when ElementAnalyzer calls
          # capture { @printer.visit(element) } for inline-length checks.
          unless preserved_element?(tag_name) || @element_formatting_analysis.key?(node)
            @element_formatting_analysis[node] = nil # registers key now so recursive visit skips re-analysis
            analyzer = ElementAnalyzer.new(self, max_line_length, indent_width)
            @element_formatting_analysis[node] = analyzer.analyze(node)
          end

          visit(node.open_tag)

          unless node.is_void
            visit_element_body(node)
            visit(node.close_tag) if node.close_tag
          end
        end
      ensure
        @element_stack.pop
      end

      # Visit HTML open tag node.
      # Dispatches to inline or multiline rendering based on pre-computed
      # ElementAnalysis. Falls back to push_to_last_line for preserved elements
      # and during recursive analysis captures.
      #
      # @rbs override
      def visit_html_open_tag_node(node) # rubocop:disable Metrics/AbcSize
        analysis = @element_formatting_analysis[current_element]

        if analysis
          inline_attrs = render_attributes_inline(node)
          tag_str = "<#{current_tag_name}#{inline_attrs}#{node.tag_closing.value}"

          if analysis.open_tag_inline
            if @inline_mode
              push_to_last_line(tag_str)
            else
              push(indent + tag_str)
            end
          else
            render_multiline_attributes(current_tag_name, node.child_nodes, void_element?(current_tag_name))
          end
        else
          # Fallback: used for preserved elements and during recursive analysis captures
          push_to_last_line(node.tag_opening.value)
          push_to_last_line(node.tag_name.value)
          push_to_last_line(render_attributes_inline(node))
          push_to_last_line(node.tag_closing.value)
        end
      end

      # Visit HTML close tag node.
      # Appends inline when analysis says close_tag_inline or when in inline mode.
      # Otherwise pushes to a new indented line.
      # Falls back to push_to_last_line for preserved elements (no analysis).
      #
      # @rbs override
      def visit_html_close_tag_node(_node)
        analysis = @element_formatting_analysis[current_element]
        closing = "</#{current_tag_name}>"

        if !analysis || analysis.close_tag_inline || @inline_mode
          push_to_last_line(closing)
        else
          push_with_indent(closing)
        end
      end

      # Return the formatted output string.
      #
      def formatted_output #: String
        @lines.join("\n")
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

      # -- ERB Formatting --

      # Visit ERB content node.
      # Routes comment nodes (<%# ... %>) to visit_erb_comment_node.
      # All other ERB content nodes are printed with normalized spacing.
      #
      # @rbs override
      def visit_erb_content_node(node)
        if node.tag_opening&.value == "<%#"
          visit_erb_comment_node(node)
          return
        end

        print_erb_node(node)
      end

      # Visit ERB end node (<% end %>).
      # Normalizes spacing and outputs using the push-based buffer.
      #
      # @rbs override
      def visit_erb_end_node(node)
        print_erb_node(node)
      end

      # Visit ERB if node.
      # Dispatches to inline mode (inside attributes) or block mode (normal).
      #
      # @rbs override
      def visit_erb_if_node(node)
        track_boundary(node) do
          if @inline_mode
            visit_erb_if_inline(node)
          else
            visit_erb_if_block(node)
          end
        end
      end

      # Visit ERB block node (each, map, etc.).
      # Prints the opening ERB tag, then visits the body with increased indentation,
      # delegating to text-flow or element-children visitors based on context.
      # Finally visits the end node.
      #
      # @rbs override
      def visit_erb_block_node(node)
        track_boundary(node) do
          print_erb_node(node)

          with_indent do
            has_text_flow = in_text_flow_context?(nil, node.body)

            if has_text_flow
              visit_text_flow_children(node.body)
            else
              visit_element_children(node.body, nil)
            end
          end

          visit(node.end_node) if node.end_node
        end
      end

      # Visit ERB unless node.
      # Prints the unless tag, visits statements with increased indentation,
      # optionally visits else_clause, then visits end_node.
      #
      # @rbs override
      def visit_erb_unless_node(node)
        track_boundary(node) do
          print_erb_node(node)

          with_indent do
            node.statements.each { visit(_1) }
          end

          visit(node.else_clause) if node.else_clause
          visit(node.end_node) if node.end_node
        end
      end

      # Visit ERB else node.
      # Prints the else tag and visits statements.
      # In inline mode, visits statements without indentation; otherwise with indentation.
      #
      # @rbs override
      def visit_erb_else_node(node)
        print_erb_node(node)

        if @inline_mode
          node.statements.each { visit(_1) }
        else
          with_indent do
            node.statements.each { visit(_1) }
          end
        end
      end

      # Visit ERB case node.
      # Prints the case tag, visits each when condition (conditions),
      # optionally visits else_clause, then visits end_node.
      #
      # @rbs override
      def visit_erb_case_node(node)
        track_boundary(node) do
          print_erb_node(node)

          with_indent do
            node.children.each { visit(_1) }
          end

          node.conditions.each { visit(_1) }

          visit(node.else_clause) if node.else_clause
          visit(node.end_node) if node.end_node
        end
      end

      # Visit ERB when node (inside case).
      # Prints the when tag and visits statements with increased indentation.
      #
      # @rbs override
      def visit_erb_when_node(node)
        print_erb_node(node)

        with_indent do
          node.statements.each { visit(_1) }
        end
      end

      # Visit ERB case/in node (pattern matching).
      # Prints the case tag, visits direct children (content between case and first in),
      # visits each in condition, optionally visits else_clause, then visits end_node.
      #
      # @rbs override
      def visit_erb_case_match_node(node)
        track_boundary(node) do
          print_erb_node(node)

          with_indent do
            node.children.each { visit(_1) }
          end

          node.conditions.each { visit(_1) }

          visit(node.else_clause) if node.else_clause
          visit(node.end_node) if node.end_node
        end
      end

      # Visit ERB in node (inside case/in pattern matching).
      # Prints the in tag and visits statements with increased indentation.
      #
      # @rbs override
      def visit_erb_in_node(node)
        print_erb_node(node)

        with_indent do
          node.statements.each { visit(_1) }
        end
      end

      # Visit ERB for node.
      # Prints the for tag, visits statements with increased indentation,
      # then visits end_node.
      #
      # @rbs override
      def visit_erb_for_node(node)
        track_boundary(node) do
          print_erb_node(node)

          with_indent do
            node.statements.each { visit(_1) }
          end

          visit(node.end_node) if node.end_node
        end
      end

      # Visit ERB while node (same pattern as for).
      #
      # @rbs override
      def visit_erb_while_node(node)
        visit_erb_for_node(node)
      end

      # Visit ERB until node (same pattern as for).
      #
      # @rbs override
      def visit_erb_until_node(node)
        visit_erb_for_node(node)
      end

      private

      # Return the element currently being visited (top of element stack).
      # Raises if called outside of visit_html_element_node context.
      #
      def current_element #: Herb::AST::HTMLElementNode
        @element_stack.last || raise("current_element called outside of element context")
      end

      # Return the tag name of the current element.
      #
      def current_tag_name #: String
        current_element.tag_name&.value || ""
      end

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

      # Visit the body of an HTML element.
      # For preserved elements (script, style, pre, textarea), content is output
      # as-is using IdentityPrinter. For elements with inline content analysis,
      # body is rendered in inline mode. For block elements, content is formatted
      # with increased indentation.
      #
      # @rbs node: Herb::AST::HTMLElementNode
      def visit_element_body(node) #: void # rubocop:disable Metrics/PerceivedComplexity
        tag_name = node.tag_name&.value || ""

        if preserved_element?(tag_name)
          # Preserve content as-is for script, style, pre, textarea
          node.body.each do |child|
            push_to_last_line(::Herb::Printer::IdentityPrinter.print(child))
          end
        else
          analysis = @element_formatting_analysis[node]

          if analysis&.element_content_inline
            # Render inline: visit all children appended to the current line
            with_inline_mode { node.body.each { visit(_1) } }
          else
            # Block: indent and visit each child on its own line
            with_indent do
              node.body.each { visit(_1) }
            end
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
        parts = open_tag.child_nodes.filter_map do |child|
          case child
          when Herb::AST::HTMLAttributeNode
            " #{render_attribute(child)}"
          when Herb::AST::ERBIfNode, Herb::AST::ERBBlockNode
            captured = capture { with_inline_mode { visit(child) } }
            " #{captured.join}"
          end
        end
        parts.join
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

      # Render the content of an attribute value node.
      # Formats ERB control flow nodes inline using the push-based visitor.
      # Other non-literal nodes fall back to IdentityPrinter.
      #
      # @rbs attribute_value: Herb::AST::HTMLAttributeValueNode
      def render_attribute_value_content(attribute_value) #: String
        attribute_value.children.map do |child|
          case child
          when Herb::AST::LiteralNode
            child.content
          when Herb::AST::ERBIfNode, Herb::AST::ERBBlockNode
            capture { with_inline_mode { visit(child) } }.join
          else
            ::Herb::Printer::IdentityPrinter.print(child)
          end
        end.join
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
        "\n#{lines.map { "  #{_1}" }.join("\n")}\n"
      end

      # -- ERB Control Flow --

      # Visit ERB comment node (<%# ... %>).
      # Handles comment formatting for both single and multi-line comments.
      # Single-line or collapsible multi-line: normalizes to <%# content %>.
      # True multi-line: formats as block with opening <%#, indented content lines,
      # and closing %> on its own line.
      #
      # @rbs node: Herb::AST::ERBContentNode
      def visit_erb_comment_node(node) #: void # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        content = token_value(node.content)
        content_trimmed_lines = content.split("\n").map(&:strip).reject(&:empty?)

        case content_trimmed_lines.length
        when 0
          formatted = "<%#%>"
          @inline_mode ? push_to_last_line(formatted) : push_with_indent(formatted)
        when 1
          formatted = "<%# #{content_trimmed_lines.first} %>"
          @inline_mode ? push_to_last_line(formatted) : push_with_indent(formatted)
        else
          if @inline_mode
            push_to_last_line("<%# #{content_trimmed_lines.join(' ')} %>")
          else
            content_lines = content.split("\n")
            first_line_empty = content_lines.first&.strip&.empty?
            dedented_lines = dedent(first_line_empty ? content : content.lstrip).split("\n")
            dedented_lines.shift while dedented_lines.first&.strip&.empty?
            dedented_lines.pop while dedented_lines.last&.strip&.empty?
            push_with_indent("<%#")
            with_indent { dedented_lines.each { push_with_indent(_1) } }
            push_with_indent("%>")
          end
        end
      end

      # Visit ERB if node in inline mode (inside attributes).
      # Handles conditional rendering of attributes in open tags.
      # In token-list attributes (e.g., class, data-controller, data-action),
      # adds spaces before each child and before the closing <% end %> tag.
      #
      # @rbs node: Herb::AST::ERBIfNode
      def visit_erb_if_inline(node) #: void
        print_erb_node(node)

        node.statements.each { visit_erb_if_inline_statement(_1) }

        has_html_attributes = node.statements.any? { _1.is_a?(Herb::AST::HTMLAttributeNode) }

        push(" ") if (has_html_attributes || in_token_list_attribute?) && node.end_node

        visit(node.subsequent) if node.subsequent
        visit(node.end_node) if node.end_node
      end

      # Visit a single statement child of an ERBIfNode in inline mode.
      # HTMLAttributeNodes are rendered as attribute strings.
      # Text content is pushed directly. Other nodes are visited normally.
      # In token-list attribute context, a space is added before each child.
      #
      # @rbs child: Herb::AST::Node
      def visit_erb_if_inline_statement(child) #: void
        if child.is_a?(Herb::AST::HTMLAttributeNode)
          push(" ")
          push(render_attribute(child))
        elsif child.is_a?(Herb::AST::LiteralNode) || child.is_a?(Herb::AST::HTMLTextNode)
          push(" ") if in_token_list_attribute?
          push_to_last_line(child.content)
        else
          push(" ") if in_token_list_attribute?
          visit(child)
        end
      end

      # Visit ERB if node in block mode (normal, outside attributes).
      # Implemented in Task 2.25.
      #
      # @rbs node: Herb::AST::ERBIfNode
      def visit_erb_if_block(node) #: void
        print_erb_node(node)

        with_indent do
          node.statements.each { visit(_1) }
        end

        visit(node.subsequent) if node.subsequent
        visit(node.end_node) if node.end_node
      end

      # Check if children form a text flow context.
      # Returns true when: non-empty text content exists, non-text children
      # exist, and all non-text children are inline elements or ERB content nodes.
      #
      # @rbs _parent: Herb::AST::Node?
      # @rbs children: Array[Herb::AST::Node]
      def in_text_flow_context?(_parent, children) #: bool # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        has_text_content = children.any? do |child|
          child.is_a?(Herb::AST::HTMLTextNode) && !child.content.strip.empty?
        end

        non_text_children = children.reject do |child|
          child.is_a?(Herb::AST::HTMLTextNode)
        end

        return false unless has_text_content
        return false if non_text_children.empty?

        non_text_children.all? do |child|
          next true if child.is_a?(Herb::AST::ERBContentNode)

          if child.is_a?(Herb::AST::HTMLElementNode)
            tag_name = get_tag_name(child)
            inline_element?(tag_name)
          else
            false
          end
        end
      end

      # Visit children in text flow mode.
      # Delegates to build_and_wrap_text_flow for inline content wrapping.
      # Note: Full implementation provided in Task 2.34 (Part F).
      #
      # @rbs children: Array[Herb::AST::Node]
      def visit_text_flow_children(children) #: void
        children.each { visit(_1) }
      end

      # Visit children as block elements, skipping pure whitespace nodes.
      # Note: Full implementation provided in Task 2.34 (Part F).
      #
      # @rbs children: Array[Herb::AST::Node]
      # @rbs _parent: Herb::AST::HTMLElementNode?
      def visit_element_children(children, _parent) #: void
        children.each do |child|
          next if pure_whitespace_node?(child)

          visit(child)
        end
      end

      # Check whether the printer is currently rendering inside a token-list attribute.
      # Token-list attributes (e.g., class, data-controller, data-action) separate
      # values with spaces, so ERB conditionals within them need space padding.
      #
      def in_token_list_attribute? #: bool
        !@current_attribute_name.nil? &&
          FormatHelpers::TOKEN_LIST_ATTRIBUTES.include?(@current_attribute_name)
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

      # Reconstruct an ERB node as a string.
      # When with_formatting is true, the content is normalized via format_erb_content.
      #
      # @rbs node: Herb::AST::ERBContentNode
      # @rbs with_formatting: bool
      def reconstruct_erb_node(node, with_formatting: true) #: String
        open = token_value(node.tag_opening)
        close = token_value(node.tag_closing)
        content = token_value(node.content)

        inner = with_formatting ? format_erb_content(content) : content

        open + inner + close
      end

      # Print an ERB node to the output buffer.
      # In inline mode, appends to the last line without a newline separator.
      # Otherwise, pushes a new line with the current indent prepended.
      #
      # @rbs node: Herb::AST::ERBContentNode
      def print_erb_node(node) #: void
        erb_text = reconstruct_erb_node(node, with_formatting: true)

        if @inline_mode
          push_to_last_line(erb_text)
        else
          push(indent + erb_text)
        end
      end
    end
  end
end
