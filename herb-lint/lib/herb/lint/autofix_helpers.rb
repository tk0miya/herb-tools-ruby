# frozen_string_literal: true

module Herb
  module Lint
    # Utility helpers for autofix implementations.
    # Provides common methods for locating parents and finding mutable arrays
    # in the AST during autofix operations.
    module AutofixHelpers
      # Find the parent node of a given node in the AST.
      # Wrapper around NodeLocator.find_parent for convenience.
      #
      # @rbs parse_result: Herb::ParseResult -- the parse result to search
      # @rbs node: Herb::AST::Node -- the node to find the parent of
      def find_parent(parse_result, node) #: Herb::AST::Node?
        NodeLocator.find_parent(parse_result, node)
      end

      # Find the mutable array that contains the given node within its parent.
      # Returns the parent's children or body array that contains the node,
      # or nil if the node is not found in any array.
      #
      # This is used to perform array-based node replacement during autofix.
      #
      # @rbs parent: Herb::AST::Node -- the parent node to search
      # @rbs node: Herb::AST::Node -- the node to find within the parent
      def parent_array_for(parent, node) #: Array[Herb::AST::Node]?
        if parent.respond_to?(:children) && parent.children.include?(node)
          parent.children
        elsif parent.respond_to?(:body) && parent.body.is_a?(Array) && parent.body.include?(node)
          parent.body
        end
      end

      # Replace a node in the AST with a new node.
      # Finds the parent, locates the array containing the old node,
      # and replaces it with the new node.
      #
      # This is a convenience method that combines find_parent, parent_array_for,
      # and array index replacement.
      #
      # @rbs parse_result: Herb::ParseResult -- the parse result to search
      # @rbs old_node: Herb::AST::Node -- the node to replace
      # @rbs new_node: Herb::AST::Node -- the replacement node
      def replace_node(parse_result, old_node, new_node) #: bool # rubocop:disable Naming/PredicateMethod
        parent = find_parent(parse_result, old_node)
        return false unless parent

        parent_array = parent_array_for(parent, old_node)
        return false unless parent_array

        index = parent_array.index(old_node)
        return false unless index

        parent_array[index] = new_node
        true
      end

      # Create a new token by copying an existing token with optional attribute overrides.
      # This is useful for creating modified tokens during autofix operations.
      #
      # @rbs token: Herb::Token -- the token to copy
      # @rbs content: String? -- override the token content (value)
      # @rbs range: Herb::Range? -- override the token range
      # @rbs location: Herb::Location? -- override the token location
      # @rbs type: String? -- override the token type
      def copy_token(token, content: nil, range: nil, location: nil, type: nil) #: Herb::Token
        Herb::Token.new(
          content || token.value,
          range || token.range,
          location || token.location,
          type || token.type
        )
      end

      # Create a new ERBContentNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB content nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBContentNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs analyzed_ruby: nil -- override the analyzed_ruby attribute
      # @rbs parsed: bool? -- override the parsed flag
      # @rbs valid: bool? -- override the valid flag
      def copy_erb_content_node( # rubocop:disable Metrics/ParameterLists
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        analyzed_ruby: nil,
        parsed: nil,
        valid: nil
      ) #: Herb::AST::ERBContentNode
        Herb::AST::ERBContentNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          analyzed_ruby || node.analyzed_ruby,
          parsed.nil? ? node.parsed : parsed,
          valid.nil? ? node.valid : valid
        )
      end
    end
  end
end
