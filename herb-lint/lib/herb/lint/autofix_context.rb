# frozen_string_literal: true

module Herb
  module Lint
    AutofixContext = Data.define(
      :rule,          #: Herb::Lint::Rules::VisitorRule | Herb::Lint::Rules::SourceRule
      :node,          #: Herb::AST::Node?
      :start_offset,  #: Integer?
      :end_offset     #: Integer?
    )

    # Bridges the check phase and autofix phase.
    # Carries a direct reference to the offending AST node (for VisitorRule) or
    # source offsets (for SourceRule) and the rule instance that can fix it.
    class AutofixContext
      #: (rule: Herb::Lint::Rules::VisitorRule, node: Herb::AST::Node) -> void
      #: (rule: Herb::Lint::Rules::SourceRule, start_offset: Integer, end_offset: Integer) -> void
      def initialize(rule:, node: nil, start_offset: nil, end_offset: nil)
        super
      end

      # Returns true when this is a source rule context (has offset information).
      def source_rule? #: bool
        !start_offset.nil?
      end

      # Returns true when this is a visitor rule context (has node information).
      def visitor_rule? #: bool
        !node.nil?
      end

      # Returns true when the rule can autofix this offense.
      # Safe autofixes are always allowed.
      # Unsafe autofixes require unsafe: true.
      # @rbs unsafe: bool
      def autofixable?(unsafe: false) #: bool
        return true if rule.class.safe_autofixable?
        return true if unsafe && rule.class.unsafe_autofixable?

        false
      end
    end
  end
end
