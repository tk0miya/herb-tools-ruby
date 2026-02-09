# frozen_string_literal: true

FactoryBot.define do
  factory :autofix_context, class: "Herb::Lint::AutofixContext" do
    node { Herb.parse("").value }
    rule_class { Herb::Lint::Rules::Html::TagNameLowercase }

    initialize_with { new(node:, rule_class:) }
  end
end
