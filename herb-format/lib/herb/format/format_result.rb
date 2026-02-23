# frozen_string_literal: true

require "diff/lcs"

module Herb
  module Format
    # Represents the formatting result for a single file.
    FormatResult = Data.define(
      :file_path,  #: String
      :original,   #: String
      :formatted,  #: String
      :ignored,    #: bool
      :error       #: StandardError?
    )

    # :nodoc:
    class FormatResult
      # @rbs file_path: String
      # @rbs original: String
      # @rbs formatted: String
      # @rbs ignored: bool
      # @rbs error: StandardError?
      def initialize(file_path:, original:, formatted:, ignored: false, error: nil) #: void
        super
      end

      def ignored? = ignored #: bool
      def error? = !error.nil? #: bool
      def changed? = original != formatted #: bool

      def diff #: String?
        return nil unless changed?

        generate_unified_diff
      end

      def to_h #: Hash[Symbol, untyped]
        {
          file_path:,
          changed: changed?,
          ignored: ignored?,
          error: error&.message
        }
      end

      private

      def generate_unified_diff #: String # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        original_lines = original.lines
        formatted_lines = formatted.lines

        diffs = Diff::LCS.diff(original_lines, formatted_lines)
        return "" if diffs.empty?

        output = []
        output << "--- #{file_path}\t(original)"
        output << "+++ #{file_path}\t(formatted)"

        diffs.each do |hunk|
          # Calculate line numbers for hunk header
          old_start = hunk.first.position + 1
          new_start = hunk.first.position + 1

          old_length = hunk.count { ["-", "!"].include?(_1.action) }
          new_length = hunk.count { ["+", "!"].include?(_1.action) }

          output << "@@ -#{old_start},#{old_length} +#{new_start},#{new_length} @@"

          hunk.each do |change|
            case change.action
            when "-", "!"
              output << "-#{change.element}"
            when "+"
              output << "+#{change.element}"
            end
          end
        end

        output.join
      end
    end
  end
end
