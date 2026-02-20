# frozen_string_literal: true

module Herb
  module Format
    # FormatHelpers module provides constants and helper functions for formatting.
    #
    # This module contains all the constants and helper functions used by the
    # FormatPrinter to make formatting decisions, analyze nodes, and determine
    # layout strategies.
    module FormatHelpers # rubocop:disable Metrics/ModuleLength
      # ============================================================
      # Constants
      # ============================================================

      # HTML inline elements that should be kept on the same line when possible.
      # These elements typically don't start on a new line and flow with text.
      INLINE_ELEMENTS = Set.new(%w[
                                  a abbr acronym b bdo big br cite code dfn em hr i img kbd label
                                  map object q samp small span strong sub sup tt var del ins mark s u time wbr
                                ]).freeze #: Set[String]

      # Elements whose content should be preserved as-is without formatting.
      # These elements contain content where whitespace is significant.
      CONTENT_PRESERVING_ELEMENTS = Set.new(%w[script style pre textarea]).freeze #: Set[String]

      # Container elements that can have blank lines between children.
      # These are typically structural/semantic containers.
      SPACEABLE_CONTAINERS = Set.new(%w[
                                       div section article main header footer aside figure
                                       details summary dialog fieldset
                                     ]).freeze #: Set[String]

      # Attributes whose values are space-separated token lists.
      # These require special handling to ensure spaces around dynamic content.
      TOKEN_LIST_ATTRIBUTES = Set.new(%w[class data-controller data-action]).freeze #: Set[String]

      # Attributes that can be formatted (wrapped, normalized).
      # Key '*' applies to all elements, specific element names for element-specific attributes.
      FORMATTABLE_ATTRIBUTES = {
        "*" => ["class"],
        "img" => %w[srcset sizes]
      }.freeze #: Hash[String, Array[String]]

      # Regular expression matching ASCII whitespace characters.
      # Used for normalizing whitespace in text content.
      ASCII_WHITESPACE = /[ \t\n\r]+/ #: Regexp

      # ============================================================
      # Node Type Detection
      # ============================================================

      # Check if a node is pure whitespace (HTMLTextNode with only whitespace).
      # Note: WhitespaceNode is NOT considered "pure whitespace".
      #
      # @rbs node: Herb::AST::Node
      def pure_whitespace_node?(node) #: bool
        node.is_a?(Herb::AST::HTMLTextNode) && node.content.strip.empty?
      end

      # Check if a node is non-whitespace (has meaningful content).
      #
      # @rbs node: Herb::AST::Node
      def non_whitespace_node?(node) #: bool
        return false if node.is_a?(Herb::AST::WhitespaceNode)
        return node.content.strip != "" if node.is_a?(Herb::AST::HTMLTextNode)

        true
      end

      # Check if a tag name is an inline element.
      #
      # @rbs tag_name: String
      def inline_element?(tag_name) #: bool
        INLINE_ELEMENTS.include?(tag_name.downcase)
      end

      # Check if a tag name is content-preserving.
      #
      # @rbs tag_name: String
      def content_preserving?(tag_name) #: bool
        CONTENT_PRESERVING_ELEMENTS.include?(tag_name.downcase)
      end

      # Check if a node is block-level (not inline).
      #
      # @rbs node: Herb::AST::Node
      def block_level_node?(node) #: bool
        return false unless node.is_a?(Herb::AST::HTMLElementNode)

        tag_name = node.tag_name&.value || ""
        !inline_element?(tag_name)
      end

      # Check if a node is a line-breaking element (br or hr).
      #
      # @rbs node: Herb::AST::Node
      def line_breaking_element?(node) #: bool
        return false unless node.is_a?(Herb::AST::HTMLElementNode)

        tag_name = node.tag_name&.value || ""
        %w[br hr].include?(tag_name.downcase)
      end

      # Check if a child is insignificant (should be filtered out).
      #
      # @rbs child: Herb::AST::Node
      def insignificant_child?(child) #: bool
        # Preserve single space
        return false if child.is_a?(Herb::AST::HTMLTextNode) && child.content == " "

        child.is_a?(Herb::AST::WhitespaceNode) || pure_whitespace_node?(child)
      end

      # Check if an HTML element is inline.
      #
      # @rbs child: Herb::AST::HTMLElementNode
      def inline_html_element?(child) #: bool
        tag_name = child.tag_name&.value || ""
        inline_element?(tag_name)
      end

      # Check if a text node is non-empty.
      #
      # @rbs child: Herb::AST::HTMLTextNode
      def non_empty_text_node?(child) #: bool
        !child.content.strip.empty?
      end

      # Check if a node is an ERB node.
      #
      # @rbs node: Herb::AST::Node
      def erb_node?(node) #: bool
        node.class.name.include?("ERB")
      end

      # Check if a node is an ERB control flow node.
      #
      # @rbs node: Herb::AST::Node
      def erb_control_flow_node?(node) #: bool
        node.is_a?(Herb::AST::ERBIfNode) ||
          node.is_a?(Herb::AST::ERBUnlessNode) ||
          node.is_a?(Herb::AST::ERBCaseNode) ||
          node.is_a?(Herb::AST::ERBBlockNode)
      end

      # Check if a node is a herb:disable comment (<%# herb:disable %>).
      # These comments disable formatting for adjacent content.
      #
      # @rbs node: Herb::AST::Node
      def herb_disable_comment?(node) #: bool
        return false unless node.is_a?(Herb::AST::ERBContentNode)
        return false unless node.tag_opening&.value == "<%#"

        content = node.content&.value || ""
        content.strip.start_with?("herb:disable")
      end

      # ============================================================
      # Utility Functions
      # ============================================================

      # Remove common leading whitespace from multi-line text.
      # Blank lines are preserved as-is.
      #
      # @rbs text: String
      def dedent(text) #: String
        lines = text.split("\n")
        min_indent = lines.reject { _1.strip.empty? }
                          .map { _1[/^\s*/].length }
                          .min || 0

        lines.map { _1.strip.empty? ? _1 : _1[min_indent..] }.join("\n")
      end

      # Get the tag name from an HTMLElementNode.
      # Returns an empty string if not available.
      #
      # @rbs element_node: Herb::AST::HTMLElementNode
      def get_tag_name(element_node) #: String
        element_node.tag_name&.value || ""
      end

      # ============================================================
      # Sibling & Child Search/Analysis
      # ============================================================

      # Find the index of the previous meaningful (non-whitespace) sibling.
      # Returns nil if no meaningful sibling exists before current_index.
      #
      # @rbs siblings: Array[Herb::AST::Node]
      # @rbs current_index: Integer
      def find_previous_meaningful_sibling(siblings, current_index) #: Integer?
        (current_index - 1).downto(0) do |i|
          node = siblings[i]
          return i if non_whitespace_node?(node)
        end

        nil
      end

      # Check if there is whitespace between two indices in children array.
      #
      # @rbs children: Array[Herb::AST::Node]
      # @rbs start_index: Integer
      # @rbs end_index: Integer
      def whitespace_between?(children, start_index, end_index) #: bool
        return false if start_index >= end_index

        ((start_index + 1)...end_index).any? do |i|
          node = children[i]
          node.is_a?(Herb::AST::WhitespaceNode) ||
            pure_whitespace_node?(node)
        end
      end

      # Filter significant children from body, preserving single spaces.
      # Excludes empty text nodes and WhitespaceNode, but preserves single space " ".
      #
      # @rbs body: Array[Herb::AST::Node]
      def filter_significant_children(body) #: Array[Herb::AST::Node]
        body.reject do |child|
          insignificant_child?(child)
        end
      end

      # Count consecutive inline elements/ERB from start of children.
      # Stops when interrupted by whitespace, block element, or non-inline content.
      #
      # @rbs children: Array[Herb::AST::Node]
      def count_adjacent_inline_elements(children) #: Integer
        count = 0

        children.each do |child|
          break if child.is_a?(Herb::AST::WhitespaceNode) || pure_whitespace_node?(child)
          break unless countable_inline_node?(child)

          count += 1
        end

        count
      end

      # Check if a node should be counted as an inline node.
      #
      # @rbs child: Herb::AST::Node
      def countable_inline_node?(child) #: bool
        return true if child.is_a?(Herb::AST::ERBContentNode)
        return false if erb_control_flow_node?(child)
        return inline_html_element?(child) if child.is_a?(Herb::AST::HTMLElementNode)
        return non_empty_text_node?(child) if child.is_a?(Herb::AST::HTMLTextNode)

        false
      end

      # ============================================================
      # Content Analysis
      # ============================================================

      # Check if any text nodes in children contain newlines.
      # Recursively checks nested element bodies.
      #
      # @rbs children: Array[Herb::AST::Node]
      def multiline_text_content?(children) #: bool
        children.any? do |child|
          if child.is_a?(Herb::AST::HTMLTextNode)
            child.content.include?("\n")
          elsif child.is_a?(Herb::AST::HTMLElementNode)
            multiline_text_content?(child.body)
          else
            false
          end
        end
      end

      # Check if all nested elements are inline.
      # Recursively checks nested element bodies.
      # Returns false for DOCTYPE, HTMLComment, and ERB control flow nodes.
      #
      # @rbs children: Array[Herb::AST::Node]
      def all_nested_elements_inline?(children) #: bool
        children.all? { nested_inline_node?(_1) }
      end

      # Check if a single node qualifies as inline for nesting purposes.
      #
      # @rbs child: Herb::AST::Node
      def nested_inline_node?(child) #: bool # rubocop:disable Metrics/CyclomaticComplexity
        case child
        when Herb::AST::WhitespaceNode, Herb::AST::HTMLTextNode
          true
        when Herb::AST::HTMLCommentNode, Herb::AST::HTMLDoctypeNode
          false
        when Herb::AST::HTMLElementNode
          tag_name = child.tag_name&.value || ""
          inline_element?(tag_name) && all_nested_elements_inline?(child.body)
        else
          erb_node?(child) && !erb_control_flow_node?(child)
        end
      end

      # Check if children contain a mix of text and inline elements.
      # Returns true when both text content and inline elements (or ERB) are present.
      # Example: "Hello <em>world</em>!" has mixed text and inline content.
      # Returns false if any block-level element is present.
      #
      # @rbs children: Array[Herb::AST::Node]
      def mixed_text_and_inline_content?(children) #: bool
        return false if children.any? { block_level_node?(_1) }

        has_text = children.any? { _1.is_a?(Herb::AST::HTMLTextNode) && non_empty_text_node?(_1) }
        has_inline = children.any? { mixed_content_inline_node?(_1) }

        has_text && has_inline
      end

      # Check if a node qualifies as an inline element for mixed content detection.
      #
      # @rbs child: Herb::AST::Node
      def mixed_content_inline_node?(child) #: bool
        return true if child.is_a?(Herb::AST::HTMLElementNode) && inline_html_element?(child)

        erb_node?(child) && !erb_control_flow_node?(child)
      end

      # Check if children contain complex ERB control flow that spans multiple lines.
      # An ERB control flow node is complex if its location spans more than one line.
      #
      # @rbs children: Array[Herb::AST::Node]
      def complex_erb_control_flow?(children) #: bool
        children.any? do |child|
          erb_control_flow_node?(child) &&
            child.location.start.line != child.location.end.line
        end
      end

      # ============================================================
      # Text & Punctuation Helpers
      # ============================================================

      # Check if a space is needed between the current line and the next word.
      # Returns false when:
      # - The word is closing punctuation (e.g., ")", ".", ",")
      # - The current line ends with opening punctuation (e.g., "(", "[")
      # - The word starts with an ERB tag and the current line ends with a non-word character
      #
      # @rbs current_line: String
      # @rbs word: String
      def needs_space_between?(current_line, word) #: bool
        return false if closing_punctuation?(word)
        return false if opening_punctuation?(current_line)
        return false if starts_with_erb_tag?(word) && current_line.match?(/[^\w\s"')\]}-]$/)

        true
      end

      # Check if a word is closing punctuation (e.g., ")", ".", ",", "!").
      # No space should precede closing punctuation.
      #
      # @rbs word: String
      def closing_punctuation?(word) #: bool
        word.match?(/^[.,;:!?)}\]]+$/)
      end

      # Check if a string ends with opening punctuation (e.g., "(", "[", "{").
      # No space should follow opening punctuation.
      #
      # @rbs word: String
      def opening_punctuation?(word) #: bool
        word.match?(/[(\[{]$/)
      end

      # Check if a string ends with an ERB closing tag (%>).
      #
      # @rbs text: String
      def ends_with_erb_tag?(text) #: bool
        text.match?(/%>$/)
      end

      # Check if a string starts with an ERB opening tag (<%).
      #
      # @rbs text: String
      def starts_with_erb_tag?(text) #: bool
        text.match?(/^<%/)
      end

      # ============================================================
      # Positioning & Spacing
      # ============================================================

      # Check if a node can be appended to a previous inline element or ERB node.
      # Used internally by should_append_to_last_line?.
      #
      # @rbs child: Herb::AST::Node
      def appendable_after_inline_or_erb?(child) #: bool
        child.is_a?(Herb::AST::HTMLTextNode) ||
          child.is_a?(Herb::AST::ERBContentNode) ||
          (child.is_a?(Herb::AST::HTMLElementNode) && inline_html_element?(child))
      end

      # Should the current node be appended to the previous line (no newline)?
      # Returns true when content should flow directly from the previous content:
      # - Text immediately after an inline element (no whitespace between)
      # - Adjacent inline elements (no whitespace between)
      # - ERB content on the same line as previous inline/text content
      #
      # @rbs child: Herb::AST::Node
      # @rbs siblings: Array[Herb::AST::Node]
      # @rbs index: Integer
      def should_append_to_last_line?(child, siblings, index) #: bool # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        prev_index = find_previous_meaningful_sibling(siblings, index)
        return false unless prev_index

        prev_node = siblings[prev_index]
        return false if whitespace_between?(siblings, prev_index, index)

        if prev_node.is_a?(Herb::AST::HTMLElementNode) && inline_html_element?(prev_node)
          return appendable_after_inline_or_erb?(child)
        end

        if prev_node.is_a?(Herb::AST::HTMLTextNode) && non_empty_text_node?(prev_node)
          return child.is_a?(Herb::AST::ERBContentNode) ||
                 (child.is_a?(Herb::AST::HTMLElementNode) && inline_html_element?(child))
        end

        return appendable_after_inline_or_erb?(child) if prev_node.is_a?(Herb::AST::ERBContentNode)

        false
      end

      # Should user-intentional spacing (blank lines) be preserved?
      # Returns true when a whitespace node contains multiple newlines (\n\n)
      # and is surrounded by meaningful content nodes.
      #
      # @rbs child: Herb::AST::Node
      # @rbs siblings: Array[Herb::AST::Node]
      # @rbs index: Integer
      def should_preserve_user_spacing?(child, siblings, index) #: bool
        return false unless pure_whitespace_node?(child)
        return false unless child.content.count("\n") >= 2

        prev_index = find_previous_meaningful_sibling(siblings, index)
        return false unless prev_index

        ((index + 1)...siblings.length).any? { |i| non_whitespace_node?(siblings[i]) }
      end
    end
  end
end
