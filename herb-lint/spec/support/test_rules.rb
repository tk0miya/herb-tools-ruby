# frozen_string_literal: true

# Shared test rules for autofix testing across multiple spec files
module TestRules
  # Safe autofixable rule that clears the body of <div> elements
  #
  # Used in: autofixer_spec.rb, runner_spec.rb, autofix_context_spec.rb
  class SafeFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/safe-fixable"
    def self.description = "Test safe fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def visit_html_element_node(node)
      if tag_name(node) == "div"
        add_offense_with_autofix(
          message: "Div should be empty",
          location: node.location,
          node:
        )
      end
      super
    end

    def autofix(node, _parse_result)
      node.body.clear
      true
    end
  end

  # Unsafe autofixable rule that clears the body of <span> elements
  #
  # Used in: autofixer_spec.rb, runner_spec.rb, autofix_context_spec.rb
  class UnsafeFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/unsafe-fixable"
    def self.description = "Test unsafe fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = false
    def self.unsafe_autofixable? = true

    def visit_html_element_node(node)
      if tag_name(node) == "span"
        add_offense_with_autofix(
          message: "Span should be empty",
          location: node.location,
          node:
        )
      end
      super
    end

    def autofix(node, _parse_result)
      node.body.clear
      true
    end
  end

  # Failing autofixable rule whose autofix always returns false
  #
  # Used in: autofixer_spec.rb
  class FailingFixableRule < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "test/failing-fixable"
    def self.description = "Test failing fixable rule"
    def self.default_severity = "warning"
    def self.safe_autofixable? = true
    def self.unsafe_autofixable? = false

    def visit_html_element_node(node)
      add_offense_with_autofix(
        message: "This will fail to fix",
        location: node.location,
        node:
      )
      super
    end

    def autofix(_node, _parse_result)
      false
    end
  end
end
