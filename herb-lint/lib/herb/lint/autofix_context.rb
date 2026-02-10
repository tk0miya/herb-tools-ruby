# frozen_string_literal: true

module Herb
  module Lint
    # Bridges the check phase and autofix phase.
    # Carries a direct reference to the offending AST node and the rule instance that can fix it.
    AutofixContext = Data.define(
      :node, #: Herb::AST::Node
      :rule  #: Herb::Lint::Rules::VisitorRule
    ) do
      # Returns true when the rule can autofix this offense.
      # Safe autofixes are always allowed.
      # Unsafe autofixes require unsafe: true.
      #
      # @rbs unsafe: bool -- when true, also consider unsafe autofixes
      def autofixable?(unsafe: false) #: bool
        return true if rule.class.safe_autofixable?
        return true if unsafe && rule.class.unsafe_autofixable?

        false
      end
    end
  end
end
