# frozen_string_literal: true

FactoryBot.define do
  factory :context, class: "Herb::Format::Context" do
    transient do
      indent_width { 2 }
      max_line_length { 80 }
    end

    file_path { "test.html.erb" }
    source { "<div>test</div>" }
    config { association :formatter_config, indent_width:, max_line_length: }

    initialize_with { new(file_path:, source:, config:) }
  end
end
