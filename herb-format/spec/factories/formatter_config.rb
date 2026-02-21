# frozen_string_literal: true

FactoryBot.define do
  factory :formatter_config, class: "Herb::Config::FormatterConfig" do
    transient do
      indent_width { 2 }
      max_line_length { 80 }
    end

    initialize_with do
      new(
        "formatter" => {
          "enabled" => true,
          "indentWidth" => indent_width,
          "maxLineLength" => max_line_length
        }
      )
    end

    trait :large_indent do
      indent_width { 4 }
    end

    trait :wide do
      max_line_length { 120 }
    end
  end
end
