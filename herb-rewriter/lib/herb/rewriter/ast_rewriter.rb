# frozen_string_literal: true

module Herb
  module Rewriter
    # Abstract base class for AST-based pre-format rewriters.
    #
    # All AST rewriters must implement:
    # - self.rewriter_name: () -> String (kebab-case identifier)
    # - self.description: () -> String (human-readable description)
    # - rewrite: (Herb::AST::DocumentNode, untyped) -> Herb::AST::DocumentNode
    #
    # ASTRewriters run before the FormatPrinter step, receiving and returning
    # an AST. They can mutate the AST in place or return a modified node.
    class ASTRewriter
      attr_reader :options #: Hash[Symbol, untyped]

      def self.rewriter_name #: String
        raise NotImplementedError, "#{name} must implement self.rewriter_name"
      end

      def self.description #: String
        raise NotImplementedError, "#{name} must implement self.description"
      end

      # @rbs options: Hash[Symbol, untyped]
      def initialize(options: {}) #: void
        @options = options
      end

      # Transform AST and return modified AST.
      #
      # @rbs ast: Herb::AST::DocumentNode
      # @rbs context: untyped
      def rewrite(ast, context) #: Herb::AST::DocumentNode
        raise NotImplementedError, "#{self.class.name} must implement #rewrite"
      end

      private

      # Traverse AST and apply transformations via block.
      # The block receives each node and can return a replacement node or nil.
      #
      # @rbs node: Herb::AST::Node
      # @rbs &block: (Herb::AST::Node) -> Herb::AST::Node?
      def traverse(node, &) #: Herb::AST::Node
        # Apply block transformation to current node
        transformed = yield(node)
        node = transformed if transformed

        # Recursively traverse children
        if node.respond_to?(:child_nodes)
          node.child_nodes.each do |child|
            traverse(child, &)
          end
        end

        node
      end
    end
  end
end
