# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Helper methods for working with HTML AST nodes.
      # Provides common attribute and element queries used across lint rules.
      module NodeHelpers
        # Return all attribute nodes for an element node.
        #
        # @rbs node: Herb::AST::HTMLElementNode -- element to inspect
        def attributes(node) #: Array[Herb::AST::HTMLAttributeNode]
          return [] unless node.open_tag

          node.open_tag.children.select do |child|
            child.is_a?(Herb::AST::HTMLAttributeNode)
          end
        end

        # Find an HTML attribute by name on an element node.
        # The comparison is case-insensitive.
        #
        # @rbs node: Herb::AST::HTMLElementNode -- element to search
        # @rbs attr_name: String -- lowercase attribute name to find
        def find_attribute(node, attr_name) #: Herb::AST::HTMLAttributeNode?
          attributes(node).find do |attr|
            attribute_name(attr)&.downcase == attr_name
          end
        end

        # Check if an element node has an attribute with the given name.
        # The comparison is case-insensitive.
        #
        # @rbs node: Herb::AST::HTMLElementNode -- element to check
        # @rbs attr_name: String -- lowercase attribute name to find
        def attribute?(node, attr_name) #: bool
          !find_attribute(node, attr_name).nil?
        end

        # Extract the raw name from an attribute node.
        # Returns nil if the node is nil.
        #
        # @rbs node: Herb::AST::HTMLAttributeNode? -- attribute node
        def attribute_name(node) #: String?
          return nil if node.nil?

          node.name.children.first&.content
        end

        # Extract the text value from an attribute node.
        # Returns nil if the node is nil.
        #
        # @rbs node: Herb::AST::HTMLAttributeNode? -- attribute node
        def attribute_value(node) #: String?
          return nil if node.nil?

          value = node.value
          return nil if value.nil?

          value.children.first&.content
        end
      end
    end
  end
end
