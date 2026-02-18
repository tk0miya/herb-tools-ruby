# rbs_inline: enabled
# frozen_string_literal: true

module Herb
  module Format
    # FormatHelpers module provides constants and helper functions for formatting.
    #
    # This module contains all the constants and helper functions used by the
    # FormatPrinter to make formatting decisions, analyze nodes, and determine
    # layout strategies.
    module FormatHelpers
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

      # ============================================================
      # Sibling & Child Search/Analysis
      # ============================================================

      # Find the index of the previous meaningful (non-whitespace) sibling.
      # Returns nil if no meaningful sibling exists before current_index.
      #
      # @rbs siblings: Array[Herb::AST::Node]
      # @rbs current_index: Integer
      # @rbs return: Integer?
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
    end
  end
end
