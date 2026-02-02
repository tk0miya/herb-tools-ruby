# frozen_string_literal: true

module Herb
  module Lint
    # Bridges the check phase and autofix phase.
    # Carries the information needed to relocate the target node in a freshly-parsed AST.
    AutofixContext = Data.define(
      :node_location, #: Herb::Location
      :node_type,     #: String
      :rule_class     #: singleton(Herb::Lint::Rules::VisitorRule)
    )
  end
end
