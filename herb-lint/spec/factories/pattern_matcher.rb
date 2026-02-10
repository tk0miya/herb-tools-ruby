# frozen_string_literal: true

FactoryBot.define do
  factory :pattern_matcher, class: "Herb::Core::PatternMatcher" do
    transient do
      includes { [] }
      excludes { [] }
      only { [] }
    end

    initialize_with { new(includes:, excludes:, only:) }
  end
end
