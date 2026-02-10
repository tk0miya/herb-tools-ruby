# frozen_string_literal: true

FactoryBot.define do
  factory :context, class: "Herb::Lint::Context" do
    file_path { "test.html.erb" }
    source { "<div></div>" }
    config { Herb::Config::LinterConfig.new({}) }
    directives { Herb::Lint::DirectiveParser.parse(Herb.parse(source, track_whitespace: true), source) }
    rule_registry { Herb::Lint::RuleRegistry.new(config:) }

    initialize_with { new(file_path:, source:, config:, directives:, rule_registry:) }
  end
end
