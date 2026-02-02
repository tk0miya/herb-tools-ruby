# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows ERB silent tags inside HTML attribute names.
      #
      # ERB silent tags (`<% %>`) should not be used inside HTML tag opening sections
      # to conditionally include attributes. This pattern is difficult to read and
      # can lead to parsing issues.
      #
      # Good:
      #   <div class="<%= active? ? 'active' : '' %>">
      #   <div <%= active? ? 'class="active"' : '' %>>
      #
      # Bad:
      #   <div <% if active? %>class="active"<% end %>>
      class ErbNoSilentTagInAttributeName < VisitorRule
        def self.rule_name #: String
          "erb-no-silent-tag-in-attribute-name"
        end

        def self.description #: String
          "Disallow ERB silent tags inside HTML attribute names"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_open_tag_node(node)
          check_silent_tags_with_attributes(node)
          super
        end

        private

        # @rbs node: Herb::AST::HTMLOpenTagNode
        def check_silent_tags_with_attributes(node) #: void
          node.children.each do |child|
            check_erb_node_for_attributes(child)
          end
        end

        # Recursively check ERB node for attributes
        # @rbs node: untyped
        def check_erb_node_for_attributes(node) #: void
          if silent_erb_node_with_statements?(node)
            report_offense(node) if attribute_directly?(node)
            # Recursively check nested ERB nodes
            check_nested_erb_nodes(node)
          elsif erb_case_node?(node)
            check_case_node(node)
          end
        end

        # Check nested ERB nodes in statements
        # @rbs node: untyped
        def check_nested_erb_nodes(node) #: void
          return unless node.respond_to?(:statements)
          return if node.statements.nil?

          node.statements.each do |stmt|
            check_erb_node_for_attributes(stmt)
          end
        end

        # Check ERBCaseNode for attributes in when clauses
        # @rbs node: untyped
        def check_case_node(node) #: void
          return unless node.respond_to?(:conditions)
          return if node.conditions.nil?
          return unless case_has_attribute?(node)

          report_offense(node)
        end

        # Check if a node is a silent ERB node with statements
        # @rbs node: untyped
        def silent_erb_node_with_statements?(node) #: bool
          node.respond_to?(:statements) && !node.statements.nil?
        end

        # Check if a node is an ERBCaseNode
        # @rbs node: untyped
        def erb_case_node?(node) #: bool
          node.is_a?(Herb::AST::ERBCaseNode)
        end

        # Check if case node has attributes in when clauses
        # @rbs node: untyped
        def case_has_attribute?(node) #: bool
          node.conditions.any? do |when_node|
            when_node.respond_to?(:statements) &&
              when_node.statements&.any? { |stmt| stmt.is_a?(Herb::AST::HTMLAttributeNode) }
          end
        end

        # Check if node's statements directly contain an HTMLAttributeNode
        # @rbs node: untyped
        def attribute_directly?(node) #: bool
          return false unless node.respond_to?(:statements)
          return false if node.statements.nil?

          node.statements.any? { |stmt| stmt.is_a?(Herb::AST::HTMLAttributeNode) }
        end

        # Report offense for silent ERB tag with attributes
        # @rbs node: untyped
        def report_offense(node) #: void
          add_offense(
            message: "Use output tags or ternary expressions for conditional attributes",
            location: node.location
          )
        end
      end
    end
  end
end
