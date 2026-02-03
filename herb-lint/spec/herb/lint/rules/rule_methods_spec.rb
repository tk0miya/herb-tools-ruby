# frozen_string_literal: true

RSpec.describe Herb::Lint::Rules::RuleMethods do
  describe "#add_offense_with_autofix" do
    let(:rule_class) do
      Class.new(Herb::Lint::Rules::VisitorRule) do
        def self.rule_name = "autofix-test-rule"
        def self.description = "Test rule with autofix"
        def self.safe_autocorrectable? = true

        def visit_html_element_node(node)
          add_offense_with_autofix(
            message: "Found element",
            location: node.location,
            node:
          )
          super
        end
      end
    end

    it "creates an offense with AutofixContext" do
      source = "<div>hello</div>"
      parse_result = Herb.parse(source, track_whitespace: true)
      context = build(:context, source:)
      rule = rule_class.new
      offenses = rule.check(parse_result, context)

      expect(offenses.size).to eq(1)
      expect(offenses.first.fixable?).to be true
      expect(offenses.first.autofix_context).to be_a(Herb::Lint::AutofixContext)
      expect(offenses.first.autofix_context.rule_class).to eq(rule_class)
      expect(offenses.first.autofix_context.node).not_to be_nil
    end
  end
end
