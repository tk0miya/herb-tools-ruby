# frozen_string_literal: true

module Herb
  module Format
    module Rewriters
      # Abstract base class defining the rewriter interface.
      #
      # All rewriters must implement:
      # - self.rewriter_name: () -> String (kebab-case identifier)
      # - self.description: () -> String (human-readable description)
      # - self.phase: () -> Symbol (:pre or :post)
      # - rewrite: (Herb::AST::DocumentNode, Context) -> Herb::AST::DocumentNode
      class Base
        # @rbs! type phase = :pre | :post

        attr_reader :options #: Hash[Symbol, untyped]

        def self.rewriter_name #: String
          raise NotImplementedError, "#{name} must implement self.rewriter_name"
        end

        def self.description #: String
          raise NotImplementedError, "#{name} must implement self.description"
        end

        def self.phase #: phase
          :post # Default to post-formatting phase
        end

        # @rbs options: Hash[Symbol, untyped]
        def initialize(options: {}) #: void
          @options = options
        end

        # Transform AST and return modified AST.
        #
        # @rbs ast: Herb::AST::DocumentNode
        # @rbs context: Context
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
end
