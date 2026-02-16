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

      # Check if a node is pure whitespace (HTMLTextNode or LiteralNode with only whitespace).
      #
      # @rbs node: Herb::AST::Node
      def pure_whitespace_node?(node) #: bool
        return true if node.is_a?(Herb::AST::HTMLTextNode) && node.content.strip.empty?
        return true if node.is_a?(Herb::AST::LiteralNode) && node.content.strip.empty?

        false
      end

      # Check if a node is non-whitespace (has meaningful content).
      #
      # @rbs node: Herb::AST::Node
      def non_whitespace_node?(node) #: bool
        return false if node.is_a?(Herb::AST::WhitespaceNode)
        return node.content.strip != "" if node.is_a?(Herb::AST::HTMLTextNode)
        return node.content.strip != "" if node.is_a?(Herb::AST::LiteralNode)

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
    end
  end
end
