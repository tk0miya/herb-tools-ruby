# frozen_string_literal: true

FactoryBot.define do
  factory :aggregated_result, class: "Herb::Format::AggregatedResult" do
    transient do
      changed_count { 0 }
      ignored_count { 0 }
      error_count { 0 }
      unchanged_count { 1 }
    end

    results do
      build_list(:format_result, changed_count, :changed) +
        build_list(:format_result, ignored_count, :ignored) +
        build_list(:format_result, error_count, :with_error) +
        build_list(:format_result, unchanged_count)
    end

    initialize_with { new(results:) }

    trait :empty do
      changed_count { 0 }
      ignored_count { 0 }
      error_count { 0 }
      unchanged_count { 0 }
    end

    trait :with_changes do
      changed_count { 2 }
    end

    trait :with_errors do
      error_count { 1 }
    end

    trait :all_formatted do
      changed_count { 0 }
      error_count { 0 }
      unchanged_count { 3 }
    end
  end
end
