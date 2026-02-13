# frozen_string_literal: true

module Herb
  module Format
    # Aggregates formatting results across multiple files.
    AggregatedResult = Data.define(
      :results #: Array[FormatResult]
    )

    # :nodoc:
    class AggregatedResult
      def file_count = results.size #: Integer

      def changed_count = results.count(&:changed?) #: Integer

      def ignored_count = results.count(&:ignored?) #: Integer

      def error_count = results.count(&:error?) #: Integer

      def all_formatted? = changed_count.zero? && error_count.zero? #: bool

      def to_h #: Hash[Symbol, untyped]
        {
          file_count:,
          changed_count:,
          ignored_count:,
          error_count:,
          all_formatted: all_formatted?
        }
      end
    end
  end
end
