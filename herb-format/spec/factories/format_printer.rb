# frozen_string_literal: true

FactoryBot.define do
  factory :format_printer, class: "Herb::Format::FormatPrinter" do
    transient do
      format_context { association :context }
    end

    initialize_with do
      new(
        indent_width: format_context.indent_width,
        max_line_length: format_context.max_line_length,
        format_context:
      )
    end
  end
end
