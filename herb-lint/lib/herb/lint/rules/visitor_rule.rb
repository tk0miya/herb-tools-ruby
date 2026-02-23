# frozen_string_literal: true

require_relative "autofix_helpers"
require_relative "node_helpers"
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
        include AutofixHelpers
        include NodeHelpers
        include RuleMethods

        # @rbs!
        #   extend RuleMethods::ClassMethods

        # Called at the start of each investigation to allow rules to reset state.
        # Subclasses should override this method to reset any instance variables
        # that accumulate state during AST traversal.
        #
        # This hook is inspired by RuboCop's on_new_investigation pattern.
        # @rbs override
        def on_new_investigation
          # Default implementation does nothing
          # Subclasses can override to reset state
        end

        # @rbs @offenses: Array[Offense]

        # Check the document for rule violations by visiting AST nodes.
        # @rbs override
        def check(document, context)
          @offenses = []
          @context = context
          on_new_investigation
          document.visit(self)
          @offenses
        end

        private

        attr_reader :context #: Context
      end
    end
  end
end
