# frozen_string_literal: true

require_relative "rule_methods"

module Herb
  module Lint
    module Rules
      # Base class for rules that use the visitor pattern to traverse AST.
      # Inherits from Herb::Visitor and includes rule functionality.
      # Subclasses should override specific visit_xxx methods to check nodes.
      #
      # Example:
      #   class MyRule < VisitorRule
      #     def self.rule_name = "my-rule"
      #     def self.description = "My custom rule"
      #
      #     def visit_html_element_node(node)
      #       add_offense(message: "Found element", location: node.location)
      #       super
      #     end
      #   end
      class VisitorRule < Herb::Visitor
        include RuleMethods

        # @rbs!
        #   extend RuleMethods::ClassMethods

        # @rbs @offenses: Array[Offense]
        # @rbs @context: Context

        # Check the document for rule violations by visiting AST nodes.
        # @rbs override
        def check(document, context)
          @offenses = []
          @context = context
          document.visit(self)
          @offenses
        end

        # Add an offense for the current rule.
        # @rbs override
        def add_offense(message:, location:)
          @offenses << create_offense(context: @context, message: message, location: location)
        end
      end
    end
  end
end
