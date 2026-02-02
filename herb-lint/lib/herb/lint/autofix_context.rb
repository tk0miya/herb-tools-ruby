# frozen_string_literal: true

module Herb
  module Lint
    # Bridges the check phase and autofix phase.
    # Carries a direct reference to the offending AST node and the rule class that can fix it.
    AutofixContext = Data.define(
      :node,      #: Herb::AST::Node
      :rule_class #: singleton(Herb::Lint::Rules::VisitorRule)
    )
  end
end
