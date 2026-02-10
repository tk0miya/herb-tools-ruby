# frozen_string_literal: true

FactoryBot.define do
  factory :autofix_context, class: "Herb::Lint::AutofixContext" do
    node { Herb.parse("").value }
    rule { Herb::Lint::Rules::Html::TagNameLowercase.new }

    initialize_with { new(node:, rule:) }
  end
end
