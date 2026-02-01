# frozen_string_literal: true

FactoryBot.define do
  factory :lint_result, class: "Herb::Lint::LintResult" do
    file_path { "test.html.erb" }
    source { "<div></div>" }

    transient do
      error_count { 0 }
      warning_count { 0 }
    end

    offenses do
      Array.new(error_count) { build(:offense, severity: "error") } +
        Array.new(warning_count) { build(:offense, severity: "warning") }
    end

    initialize_with { new(file_path:, offenses:, source:) }

    trait :with_errors do
      error_count { 1 }
    end

    trait :with_warnings do
      warning_count { 1 }
    end
  end
end
