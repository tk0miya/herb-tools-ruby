# frozen_string_literal: true

FactoryBot.define do
  factory :lint_result, class: "Herb::Lint::LintResult" do
    file_path { "test.html.erb" }
    source { "<div></div>" }

    ignored_count { 0 }

    transient do
      error_count { 0 }
      warning_count { 0 }
      info_count { 0 }
      hint_count { 0 }
      autofixed_count { 0 }
      autofixable_count { 0 }
    end

    unfixed_offenses do
      error_offenses = Array.new(error_count) { build(:offense, severity: "error") }
      warning_offenses = Array.new(warning_count) { build(:offense, severity: "warning") }
      info_offenses = Array.new(info_count) { build(:offense, severity: "info") }
      hint_offenses = Array.new(hint_count) { build(:offense, severity: "hint") }
      fixable_offenses = Array.new(autofixable_count) { build(:offense, :autofixable) }
      error_offenses + warning_offenses + info_offenses + hint_offenses + fixable_offenses
    end

    autofixed_offenses do
      Array.new(autofixed_count) { build(:offense) }
    end

    initialize_with { new(file_path:, unfixed_offenses:, source:, ignored_count:, autofixed_offenses:) }

    trait :with_errors do
      error_count { 1 }
    end

    trait :with_warnings do
      warning_count { 1 }
    end
  end
end
