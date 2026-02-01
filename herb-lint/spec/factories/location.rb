# frozen_string_literal: true

FactoryBot.define do
  factory :location, class: "Herb::Location" do
    transient do
      start_line { 1 }
      start_column { 0 }
      end_line { start_line }
      end_column { start_column }
    end

    initialize_with do
      new(
        Herb::Position.new(start_line, start_column),
        Herb::Position.new(end_line, end_column)
      )
    end
  end
end
