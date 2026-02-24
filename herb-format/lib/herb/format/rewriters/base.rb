# frozen_string_literal: true

# rbs_inline: enabled

module Herb
  module Format
    module Rewriters
      # Abstract base class defining the rewriter interface.
      #
      # All rewriters must implement:
      # - self.rewriter_name: () -> String (kebab-case identifier)
      # - self.description: () -> String (human-readable description)
      # - self.phase: () -> phase (:pre or :post)
      # - rewrite: (Herb::AST::Node, Context) -> Herb::AST::Node
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
          :post
        end

        # @rbs options: Hash[Symbol, untyped]
        def initialize(options: {}) #: void
          @options = options
        end

        # Transform AST and return modified AST.
        #
        # @rbs ast: Herb::AST::Node
        # @rbs context: Context
        def rewrite(ast, context) #: Herb::AST::Node
          raise NotImplementedError, "#{self.class.name} must implement #rewrite"
        end

        private

        # Traverse AST and apply transformations via block.
        # The block receives each node and can return a replacement node or nil.
        #
        # @rbs node: Herb::AST::Node
        # @rbs block: Proc
        def traverse(node, &block) #: Herb::AST::Node
          transformed = block.call(node)
          node = transformed if transformed

          if node.respond_to?(:child_nodes)
            node.child_nodes.each { traverse(_1, &block) }
          end

          node
        end
      end
    end
  end
end
