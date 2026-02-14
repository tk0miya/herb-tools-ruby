# frozen_string_literal: true

FactoryBot.define do
  factory :format_result, class: "Herb::Format::FormatResult" do
    file_path { "test.html.erb" }
    original { "<div>test</div>" }
    formatted { "<div>test</div>" }
    ignored { false }
    error { nil }

    initialize_with { new(file_path:, original:, formatted:, ignored:, error:) }

    trait :changed do
      formatted { "<div>\n  test\n</div>" }
    end

    trait :ignored do
      ignored { true }
    end

    trait :with_error do
      error { StandardError.new("Parse error") }
    end
  end
end
