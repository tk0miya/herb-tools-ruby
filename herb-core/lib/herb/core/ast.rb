# frozen_string_literal: true

module Herb
  module Core
    # Shared AST constants, type aliases, and predicate methods for working
    # with Herb::AST node types.
    #
    # Include this module to gain access to the predicate methods:
    #
    #   include Herb::Core::AST
    #
    #   erb_node?(node)           #=> true/false
    #   erb_control_flow_node?(node)  #=> true/false
    module AST
      # @rbs! type erb_node = Herb::AST::ERBContentNode
      #   | Herb::AST::ERBYieldNode
      #   | Herb::AST::ERBEndNode
      #   | Herb::AST::ERBElseNode
      #   | Herb::AST::ERBIfNode
      #   | Herb::AST::ERBUnlessNode
      #   | Herb::AST::ERBCaseNode
      #   | Herb::AST::ERBCaseMatchNode
      #   | Herb::AST::ERBWhenNode
      #   | Herb::AST::ERBInNode
      #   | Herb::AST::ERBBlockNode
      #   | Herb::AST::ERBForNode
      #   | Herb::AST::ERBWhileNode
      #   | Herb::AST::ERBUntilNode
      #   | Herb::AST::ERBBeginNode
      #   | Herb::AST::ERBRescueNode
      #   | Herb::AST::ERBEnsureNode

      # @rbs! type html_node = Herb::AST::HTMLElementNode
      #   | Herb::AST::HTMLOpenTagNode
      #   | Herb::AST::HTMLCloseTagNode
      #   | Herb::AST::HTMLAttributeNode
      #   | Herb::AST::HTMLAttributeNameNode
      #   | Herb::AST::HTMLAttributeValueNode
      #   | Herb::AST::HTMLDoctypeNode
      #   | Herb::AST::HTMLCommentNode
      #   | Herb::AST::XMLDeclarationNode
      #   | Herb::AST::HTMLTextNode

      # @rbs! type node = erb_node
      #   | html_node
      #   | Herb::AST::DocumentNode
      #   | Herb::AST::LiteralNode
      #   | Herb::AST::WhitespaceNode

      # @rbs! type erb_control_flow_node = Herb::AST::ERBIfNode
      #   | Herb::AST::ERBUnlessNode
      #   | Herb::AST::ERBCaseNode
      #   | Herb::AST::ERBCaseMatchNode
      #   | Herb::AST::ERBBlockNode
      #   | Herb::AST::ERBForNode
      #   | Herb::AST::ERBWhileNode
      #   | Herb::AST::ERBUntilNode

      # All ERB node types.
      ERB_NODE_TYPES = [
        Herb::AST::ERBContentNode,
        Herb::AST::ERBYieldNode,
        Herb::AST::ERBEndNode,
        Herb::AST::ERBElseNode,
        Herb::AST::ERBIfNode,
        Herb::AST::ERBUnlessNode,
        Herb::AST::ERBCaseNode,
        Herb::AST::ERBCaseMatchNode,
        Herb::AST::ERBWhenNode,
        Herb::AST::ERBInNode,
        Herb::AST::ERBBlockNode,
        Herb::AST::ERBForNode,
        Herb::AST::ERBWhileNode,
        Herb::AST::ERBUntilNode,
        Herb::AST::ERBBeginNode,
        Herb::AST::ERBRescueNode,
        Herb::AST::ERBEnsureNode
      ].freeze #: Array[singleton(Herb::AST::Node)]

      # ERB node types that represent control flow constructs (if/unless/case/for/while/etc.).
      ERB_CONTROL_FLOW_TYPES = [
        Herb::AST::ERBIfNode,
        Herb::AST::ERBUnlessNode,
        Herb::AST::ERBCaseNode,
        Herb::AST::ERBCaseMatchNode,
        Herb::AST::ERBBlockNode,
        Herb::AST::ERBForNode,
        Herb::AST::ERBWhileNode,
        Herb::AST::ERBUntilNode
      ].freeze #: Array[singleton(Herb::AST::Node)]

      # Check if a node is any ERB node.
      #
      # @rbs node: Herb::AST::Node
      def erb_node?(node) #: bool
        ERB_NODE_TYPES.any? { node.is_a?(_1) }
      end

      # Check if a node is an ERB control flow node (if/unless/case/for/while/etc.).
      #
      # @rbs node: Herb::AST::Node
      def erb_control_flow_node?(node) #: bool
        ERB_CONTROL_FLOW_TYPES.any? { node.is_a?(_1) }
      end
    end
  end
end
