# frozen_string_literal: true

module Herb
  module Lint
    # Utility helpers for autofix implementations.
    # Provides common methods for locating parents and finding mutable arrays
    # in the AST during autofix operations.
    module AutofixHelpers # rubocop:disable Metrics/ModuleLength
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

      # Structural attribute names used to link parent nodes to child nodes
      # (e.g. ERBIfNode#end_node, ERBIfNode#subsequent, HTMLElementNode#open_tag).
      STRUCTURAL_ATTRIBUTES = %i[
        close_tag else_clause end_node ensure_clause open_tag rescue_clause subsequent
      ].freeze #: Array[Symbol]

      # Replace a node in the AST with a new node.
      #
      # First tries array-based replacement (children/body). If the node is not
      # in an array (e.g. it is a structural attribute like end_node or subsequent),
      # creates a copy of the parent with the new child and recursively replaces
      # the parent.
      #
      # @rbs parse_result: Herb::ParseResult -- the parse result to search
      # @rbs old_node: Herb::AST::Node -- the node to replace
      # @rbs new_node: Herb::AST::Node -- the replacement node
      def replace_node(parse_result, old_node, new_node) #: bool
        parent = find_parent(parse_result, old_node)
        return false unless parent

        parent_array = parent_array_for(parent, old_node)
        if parent_array
          index = parent_array.index(old_node)
          return false unless index

          parent_array[index] = new_node
          return true
        end

        replace_structural_child(parse_result, parent, old_node, new_node)
      end

      # Remove a node from the AST.
      # Finds the parent, locates the array containing the node,
      # and removes it from the array.
      #
      # This is a convenience method that combines find_parent, parent_array_for,
      # and array deletion.
      #
      # @rbs parse_result: Herb::ParseResult -- the parse result to search
      # @rbs node: Herb::AST::Node -- the node to remove
      def remove_node(parse_result, node) #: bool # rubocop:disable Naming/PredicateMethod
        parent = find_parent(parse_result, node)
        return false unless parent

        parent_array = parent_array_for(parent, node)
        return false unless parent_array

        index = parent_array.index(node)
        return false unless index

        parent_array.delete_at(index)
        true
      end

      # Build a double-quote token at the given position.
      # This is useful for adding quotes to unquoted attribute values during autofix.
      #
      # @rbs position: Herb::Position -- the position for the new token
      def build_quote_token(position) #: Herb::Token
        location = Herb::Location.new(position, position)
        range = Herb::Range.new(0, 0)
        Herb::Token.new('"', range, location, "TOKEN_QUOTE")
      end

      # Create a whitespace node for spacing.
      # Location is set to (0, 0) as it doesn't affect printer output.
      # The printer uses the AST structure (whitespace nodes) for spacing, not locations.
      #
      def build_whitespace_node #: Herb::AST::WhitespaceNode
        ws_loc = Herb::Location.new(
          Herb::Position.new(0, 0),
          Herb::Position.new(0, 1)
        )
        ws_range = Herb::Range.new(0, 1)
        ws_token = Herb::Token.new(" ", ws_range, ws_loc, "TOKEN_WHITESPACE")
        Herb::AST::WhitespaceNode.new("AST_WHITESPACE_NODE", ws_loc, [], ws_token)
      end

      # Build a new HTMLCloseTagNode from scratch using only a tag name string.
      # This is useful when adding a missing close tag during autofix operations.
      #
      # @rbs tag_name_str: String -- the tag name for the close tag (e.g. "div")
      def build_close_tag(tag_name_str) #: Herb::AST::HTMLCloseTagNode
        position = Herb::Position.new(0, 0)
        location = Herb::Location.new(position, position)
        range = Herb::Range.new(0, 0)

        tag_opening = Herb::Token.new("</", range, location, "TOKEN_HTML_TAG_START_CLOSE")
        tag_name_token = Herb::Token.new(tag_name_str, range, location, "TOKEN_IDENTIFIER")
        tag_closing = Herb::Token.new(">", range, location, "TOKEN_HTML_TAG_END")

        Herb::AST::HTMLCloseTagNode.new(
          "AST_HTML_CLOSE_TAG_NODE", location, [], tag_opening, tag_name_token, [], tag_closing
        )
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

      # Create a new HTMLOpenTagNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified open tag nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLOpenTagNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening token
      # @rbs tag_name: Herb::Token? -- override the tag name token
      # @rbs tag_closing: Herb::Token? -- override the closing token
      # @rbs children: Array[Herb::AST::Node]? -- override the children array
      # @rbs is_void: bool? -- override the is_void flag
      def copy_html_open_tag_node(
        node,
        tag_opening: nil,
        tag_name: nil,
        tag_closing: nil,
        children: nil,
        is_void: nil
      ) #: Herb::AST::HTMLOpenTagNode
        Herb::AST::HTMLOpenTagNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          tag_name || node.tag_name,
          tag_closing || node.tag_closing,
          children || node.children,
          is_void.nil? ? node.is_void : is_void
        )
      end

      # Create a new HTMLCloseTagNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified close tag nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLCloseTagNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening token
      # @rbs tag_name: Herb::Token? -- override the tag name token
      # @rbs children: Array[Herb::AST::Node]? -- override the children array
      # @rbs tag_closing: Herb::Token? -- override the closing token
      def copy_html_close_tag_node(
        node,
        tag_opening: nil,
        tag_name: nil,
        children: nil,
        tag_closing: nil
      ) #: Herb::AST::HTMLCloseTagNode
        Herb::AST::HTMLCloseTagNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          tag_name || node.tag_name,
          children || node.children,
          tag_closing || node.tag_closing
        )
      end

      # Create a new HTMLAttributeNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified attribute nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLAttributeNode -- the node to copy
      # @rbs name: Herb::AST::HTMLAttributeNameNode? -- override the name node
      # @rbs equals: Herb::Token? -- override the equals token
      # @rbs value: Herb::AST::HTMLAttributeValueNode? -- override the value node
      def copy_html_attribute_node(node, name: nil, equals: nil, value: nil) #: Herb::AST::HTMLAttributeNode
        Herb::AST::HTMLAttributeNode.new(
          node.type,
          node.location,
          node.errors,
          name || node.name,
          equals || node.equals,
          value || node.value
        )
      end

      # Create a new HTMLAttributeValueNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified attribute value nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLAttributeValueNode -- the node to copy
      # @rbs open_quote: Herb::Token? -- override the opening quote token
      # @rbs children: Array[Herb::AST::Node]? -- override the children array
      # @rbs close_quote: Herb::Token? -- override the closing quote token
      # @rbs quoted: bool? -- override the quoted flag
      def copy_html_attribute_value_node(
        node,
        open_quote: nil,
        children: nil,
        close_quote: nil,
        quoted: nil
      ) #: Herb::AST::HTMLAttributeValueNode
        Herb::AST::HTMLAttributeValueNode.new(
          node.type,
          node.location,
          node.errors,
          open_quote || node.open_quote,
          children || node.children,
          close_quote || node.close_quote,
          quoted.nil? ? node.quoted : quoted
        )
      end

      # Create a new HTMLElementNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified element nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLElementNode -- the node to copy
      # @rbs open_tag: Herb::AST::HTMLOpenTagNode? -- override the open tag
      # @rbs tag_name: Herb::Token? -- override the tag name token
      # @rbs body: Array[Herb::AST::Node]? -- override the body array
      # @rbs close_tag: Herb::AST::HTMLCloseTagNode? -- override the close tag
      # @rbs is_void: bool? -- override the is_void flag
      # @rbs source: Herb::Token? -- override the source token
      def copy_html_element_node(
        node,
        open_tag: nil,
        tag_name: nil,
        body: nil,
        close_tag: nil,
        is_void: nil,
        source: nil
      ) #: Herb::AST::HTMLElementNode
        Herb::AST::HTMLElementNode.new(
          node.type,
          node.location,
          node.errors,
          open_tag || node.open_tag,
          tag_name || node.tag_name,
          body || node.body,
          close_tag || node.close_tag,
          is_void.nil? ? node.is_void : is_void,
          source || node.source
        )
      end

      # Create a new HTMLTextNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified text nodes during autofix operations.
      #
      # @rbs node: Herb::AST::HTMLTextNode -- the node to copy
      # @rbs content: String? -- override the content string
      def copy_html_text_node(node, content: nil) #: Herb::AST::HTMLTextNode
        Herb::AST::HTMLTextNode.new(
          node.type,
          node.location,
          node.errors,
          content&.dup || node.content
        )
      end

      # Create a new ERBBeginNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB begin nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBBeginNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs rescue_clause: Herb::AST::ERBRescueNode? -- override the rescue clause
      # @rbs else_clause: Herb::AST::ERBElseNode? -- override the else clause
      # @rbs ensure_clause: Herb::AST::ERBEnsureNode? -- override the ensure clause
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_begin_node( # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        statements: nil,
        rescue_clause: nil,
        else_clause: nil,
        ensure_clause: nil,
        end_node: nil
      ) #: Herb::AST::ERBBeginNode
        Herb::AST::ERBBeginNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements,
          rescue_clause || node.rescue_clause,
          else_clause || node.else_clause,
          ensure_clause || node.ensure_clause,
          end_node || node.end_node
        )
      end

      # Create a new ERBBlockNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB block nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBBlockNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs body: Array[Herb::AST::Node]? -- override the body array
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_block_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        body: nil,
        end_node: nil
      ) #: Herb::AST::ERBBlockNode
        Herb::AST::ERBBlockNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          body || node.body,
          end_node || node.end_node
        )
      end

      # Create a new ERBCaseMatchNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB case-match nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBCaseMatchNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs children: Array[Herb::AST::Node]? -- override the children array
      # @rbs conditions: Array[Herb::AST::ERBInNode]? -- override the conditions array
      # @rbs else_clause: Herb::AST::ERBElseNode? -- override the else clause
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_case_match_node( # rubocop:disable Metrics/CyclomaticComplexity
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        children: nil,
        conditions: nil,
        else_clause: nil,
        end_node: nil
      ) #: Herb::AST::ERBCaseMatchNode
        Herb::AST::ERBCaseMatchNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          children || node.children,
          conditions || node.conditions,
          else_clause || node.else_clause,
          end_node || node.end_node
        )
      end

      # Create a new ERBCaseNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB case nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBCaseNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs children: Array[Herb::AST::Node]? -- override the children array
      # @rbs conditions: Array[Herb::AST::ERBWhenNode]? -- override the conditions array
      # @rbs else_clause: Herb::AST::ERBElseNode? -- override the else clause
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_case_node( # rubocop:disable Metrics/CyclomaticComplexity
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        children: nil,
        conditions: nil,
        else_clause: nil,
        end_node: nil
      ) #: Herb::AST::ERBCaseNode
        Herb::AST::ERBCaseNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          children || node.children,
          conditions || node.conditions,
          else_clause || node.else_clause,
          end_node || node.end_node
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
      def copy_erb_content_node(
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

      # Create a new ERBElseNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB else nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBElseNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      def copy_erb_else_node(node, tag_opening: nil, content: nil, tag_closing: nil, statements: nil) #: Herb::AST::ERBElseNode
        Herb::AST::ERBElseNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements
        )
      end

      # Create a new ERBEndNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB end nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBEndNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      def copy_erb_end_node(node, tag_opening: nil, content: nil, tag_closing: nil) #: Herb::AST::ERBEndNode
        Herb::AST::ERBEndNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing
        )
      end

      # Create a new ERBEnsureNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB ensure nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBEnsureNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      def copy_erb_ensure_node(node, tag_opening: nil, content: nil, tag_closing: nil, statements: nil) #: Herb::AST::ERBEnsureNode
        Herb::AST::ERBEnsureNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements
        )
      end

      # Create a new ERBForNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB for nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBForNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_for_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        statements: nil,
        end_node: nil
      ) #: Herb::AST::ERBForNode
        Herb::AST::ERBForNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements,
          end_node || node.end_node
        )
      end

      # Create a new ERBIfNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB if nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBIfNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs then_keyword: Herb::Token? -- override the then keyword token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs subsequent: Herb::AST::Node? -- override the subsequent node (elsif/else)
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_if_node( # rubocop:disable Metrics/CyclomaticComplexity
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        then_keyword: nil,
        statements: nil,
        subsequent: nil,
        end_node: nil
      ) #: Herb::AST::ERBIfNode
        Herb::AST::ERBIfNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          then_keyword || node.then_keyword,
          statements || node.statements,
          subsequent || node.subsequent,
          end_node || node.end_node
        )
      end

      # Create a new ERBInNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB in nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBInNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs then_keyword: Herb::Location? -- override the then keyword location
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      def copy_erb_in_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        then_keyword: nil,
        statements: nil
      ) #: Herb::AST::ERBInNode
        Herb::AST::ERBInNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          then_keyword || node.then_keyword,
          statements || node.statements
        )
      end

      # Create a new ERBRescueNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB rescue nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBRescueNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs subsequent: Herb::AST::ERBRescueNode? -- override the subsequent rescue node
      def copy_erb_rescue_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        statements: nil,
        subsequent: nil
      ) #: Herb::AST::ERBRescueNode
        Herb::AST::ERBRescueNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements,
          subsequent || node.subsequent
        )
      end

      # Create a new ERBUnlessNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB unless nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBUnlessNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs then_keyword: Herb::Token? -- override the then keyword token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs else_clause: Herb::AST::ERBElseNode? -- override the else clause node
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_unless_node( # rubocop:disable Metrics/CyclomaticComplexity
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        then_keyword: nil,
        statements: nil,
        else_clause: nil,
        end_node: nil
      ) #: Herb::AST::ERBUnlessNode
        Herb::AST::ERBUnlessNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          then_keyword || node.then_keyword,
          statements || node.statements,
          else_clause || node.else_clause,
          end_node || node.end_node
        )
      end

      # Create a new ERBUntilNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB until nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBUntilNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_until_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        statements: nil,
        end_node: nil
      ) #: Herb::AST::ERBUntilNode
        Herb::AST::ERBUntilNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements,
          end_node || node.end_node
        )
      end

      # Create a new ERBWhenNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB when nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBWhenNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs then_keyword: Herb::Location? -- override the then keyword location
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      def copy_erb_when_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        then_keyword: nil,
        statements: nil
      ) #: Herb::AST::ERBWhenNode
        Herb::AST::ERBWhenNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          then_keyword || node.then_keyword,
          statements || node.statements
        )
      end

      # Create a new ERBWhileNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB while nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBWhileNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      # @rbs statements: Array[Herb::AST::Node]? -- override the statements array
      # @rbs end_node: Herb::AST::ERBEndNode? -- override the end node
      def copy_erb_while_node(
        node,
        tag_opening: nil,
        content: nil,
        tag_closing: nil,
        statements: nil,
        end_node: nil
      ) #: Herb::AST::ERBWhileNode
        Herb::AST::ERBWhileNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing,
          statements || node.statements,
          end_node || node.end_node
        )
      end

      # Create a new ERBYieldNode by copying an existing node with optional attribute overrides.
      # This is useful for creating modified ERB yield nodes during autofix operations.
      #
      # @rbs node: Herb::AST::ERBYieldNode -- the node to copy
      # @rbs tag_opening: Herb::Token? -- override the opening tag token
      # @rbs content: Herb::Token? -- override the content token
      # @rbs tag_closing: Herb::Token? -- override the closing tag token
      def copy_erb_yield_node(node, tag_opening: nil, content: nil, tag_closing: nil) #: Herb::AST::ERBYieldNode
        Herb::AST::ERBYieldNode.new(
          node.type,
          node.location,
          node.errors,
          tag_opening || node.tag_opening,
          content || node.content,
          tag_closing || node.tag_closing
        )
      end

      private

      # Replace a node that is stored as a structural attribute of its parent
      # (e.g. end_node, subsequent, rescue_clause, else_clause, ensure_clause).
      # Creates a copy of the parent with the new child, then recursively
      # replaces the parent in the tree.
      #
      # @rbs parse_result: Herb::ParseResult
      # @rbs parent: Herb::AST::Node -- the parent node containing the structural child
      # @rbs old_node: Herb::AST::Node -- the structural child to replace
      # @rbs new_node: Herb::AST::Node -- the replacement node
      def replace_structural_child(parse_result, parent, old_node, new_node) #: bool
        attr = STRUCTURAL_ATTRIBUTES.find { parent.respond_to?(_1) && parent.send(_1).equal?(old_node) }
        return false unless attr

        new_parent = copy_erb_node(parent, attr => new_node)
        replace_node(parse_result, parent, new_parent)
      end

      public

      # Create a copy of any ERB node with overridden attributes.
      # Dispatches to the appropriate copy_erb_*_node method based on the node's class.
      #
      # rubocop:disable Layout/LineLength
      #: (Herb::AST::ERBBeginNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?rescue_clause: Herb::AST::ERBRescueNode?, ?else_clause: Herb::AST::ERBElseNode?, ?ensure_clause: Herb::AST::ERBEnsureNode?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBBeginNode
      #: (Herb::AST::ERBBlockNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?body: Array[Herb::AST::Node]?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBBlockNode
      #: (Herb::AST::ERBCaseMatchNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?children: Array[Herb::AST::Node]?, ?conditions: Array[Herb::AST::ERBInNode]?, ?else_clause: Herb::AST::ERBElseNode?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBCaseMatchNode
      #: (Herb::AST::ERBCaseNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?children: Array[Herb::AST::Node]?, ?conditions: Array[Herb::AST::ERBWhenNode]?, ?else_clause: Herb::AST::ERBElseNode?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBCaseNode
      #: (Herb::AST::ERBContentNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?analyzed_ruby: nil, ?parsed: bool?, ?valid: bool?) -> Herb::AST::ERBContentNode
      #: (Herb::AST::ERBElseNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?) -> Herb::AST::ERBElseNode
      #: (Herb::AST::ERBEndNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?) -> Herb::AST::ERBEndNode
      #: (Herb::AST::ERBEnsureNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?) -> Herb::AST::ERBEnsureNode
      #: (Herb::AST::ERBForNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBForNode
      #: (Herb::AST::ERBIfNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?then_keyword: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?subsequent: Herb::AST::Node?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBIfNode
      #: (Herb::AST::ERBInNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?then_keyword: Herb::Location?, ?statements: Array[Herb::AST::Node]?) -> Herb::AST::ERBInNode
      #: (Herb::AST::ERBRescueNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?subsequent: Herb::AST::ERBRescueNode?) -> Herb::AST::ERBRescueNode
      #: (Herb::AST::ERBUnlessNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?then_keyword: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?else_clause: Herb::AST::ERBElseNode?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBUnlessNode
      #: (Herb::AST::ERBUntilNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBUntilNode
      #: (Herb::AST::ERBWhenNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?then_keyword: Herb::Location?, ?statements: Array[Herb::AST::Node]?) -> Herb::AST::ERBWhenNode
      #: (Herb::AST::ERBWhileNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?, ?statements: Array[Herb::AST::Node]?, ?end_node: Herb::AST::ERBEndNode?) -> Herb::AST::ERBWhileNode
      #: (Herb::AST::ERBYieldNode node, ?tag_opening: Herb::Token?, ?content: Herb::Token?, ?tag_closing: Herb::Token?) -> Herb::AST::ERBYieldNode
      #: (Herb::AST::HTMLAttributeValueNode node, ?open_quote: Herb::Token?, ?children: Array[Herb::AST::Node]?, ?close_quote: Herb::Token?, ?quoted: bool?) -> Herb::AST::HTMLAttributeValueNode
      #: (Herb::AST::HTMLElementNode node, ?open_tag: Herb::AST::HTMLOpenTagNode?, ?tag_name: Herb::Token?, ?body: Array[Herb::AST::Node]?, ?close_tag: Herb::AST::HTMLCloseTagNode?, ?is_void: bool?, ?source: Herb::Token?) -> Herb::AST::HTMLElementNode
      #: (Herb::AST::HTMLOpenTagNode node, ?tag_opening: Herb::Token?, ?tag_name: Herb::Token?, ?tag_closing: Herb::Token?, ?children: Array[Herb::AST::Node]?, ?is_void: bool?) -> Herb::AST::HTMLOpenTagNode
      #: (Herb::AST::HTMLCloseTagNode node, ?tag_opening: Herb::Token?, ?tag_name: Herb::Token?, ?children: Array[Herb::AST::Node]?, ?tag_closing: Herb::Token?) -> Herb::AST::HTMLCloseTagNode
      # rubocop:enable Layout/LineLength
      def copy_erb_node(node, **overrides) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        case node
        when Herb::AST::ERBBeginNode     then copy_erb_begin_node(node, **overrides)
        when Herb::AST::ERBBlockNode     then copy_erb_block_node(node, **overrides)
        when Herb::AST::ERBCaseMatchNode then copy_erb_case_match_node(node, **overrides)
        when Herb::AST::ERBCaseNode      then copy_erb_case_node(node, **overrides)
        when Herb::AST::ERBContentNode   then copy_erb_content_node(node, **overrides)
        when Herb::AST::ERBElseNode      then copy_erb_else_node(node, **overrides)
        when Herb::AST::ERBEndNode       then copy_erb_end_node(node, **overrides)
        when Herb::AST::ERBEnsureNode    then copy_erb_ensure_node(node, **overrides)
        when Herb::AST::ERBForNode       then copy_erb_for_node(node, **overrides)
        when Herb::AST::ERBIfNode        then copy_erb_if_node(node, **overrides)
        when Herb::AST::ERBInNode        then copy_erb_in_node(node, **overrides)
        when Herb::AST::ERBRescueNode    then copy_erb_rescue_node(node, **overrides)
        when Herb::AST::ERBUnlessNode    then copy_erb_unless_node(node, **overrides)
        when Herb::AST::ERBUntilNode     then copy_erb_until_node(node, **overrides)
        when Herb::AST::ERBWhenNode      then copy_erb_when_node(node, **overrides)
        when Herb::AST::ERBWhileNode     then copy_erb_while_node(node, **overrides)
        when Herb::AST::ERBYieldNode     then copy_erb_yield_node(node, **overrides)
        when Herb::AST::HTMLAttributeValueNode then copy_html_attribute_value_node(node, **overrides)
        when Herb::AST::HTMLElementNode  then copy_html_element_node(node, **overrides)
        when Herb::AST::HTMLOpenTagNode  then copy_html_open_tag_node(node, **overrides)
        when Herb::AST::HTMLCloseTagNode then copy_html_close_tag_node(node, **overrides)
        end
      end
    end
  end
end
