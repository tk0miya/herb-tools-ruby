# frozen_string_literal: true

module Herb
  module Lint
    # Utility for finding parent nodes in an AST by object identity.
    # Used by autofix methods to locate the parent of an offending node
    # for array-based replacement.
    class NodeLocator < Herb::Visitor
      # Find the parent of a given node in the AST.
      # Uses object identity (equal?) to match the target node.
      #
      # @rbs parse_result: Herb::ParseResult -- the parse result to search
      # @rbs target_node: Herb::AST::Node -- the node to find the parent of
      def self.find_parent(parse_result, target_node) #: Herb::AST::Node?
        locator = new(target_node)
        parse_result.visit(locator)
        locator.found
      end

      attr_reader :found #: Herb::AST::Node?
      attr_reader :parent_stack #: Array[Herb::AST::Node]

      # @rbs target_node: Herb::AST::Node
      def initialize(target_node) #: void
        super()
        @target_node = target_node
        @found = nil
        @parent_stack = []
      end

      # @rbs @target_node: Herb::AST::Node

      # @rbs override
      def visit_child_nodes(node)
        @found = parent_stack.last if node.equal?(@target_node)

        return if found

        parent_stack.push(node)
        super
        parent_stack.pop
      end
    end
  end
end
