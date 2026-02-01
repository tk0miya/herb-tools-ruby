# frozen_string_literal: true

FactoryBot.define do
  factory :offense, class: "Herb::Lint::Offense" do
    rule_name { "test-rule" }
    message { "Test message" }
    severity { "error" }

    transient do
      start_line { 1 }
      start_column { 0 }
      end_line { start_line }
      end_column { start_column }
    end

    location do
      build(:location, start_line:, start_column:, end_line:, end_column:)
    end

    initialize_with { new(rule_name:, message:, severity:, location:) }
  end
end
