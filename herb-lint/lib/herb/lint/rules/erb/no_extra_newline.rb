# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-extra-newline.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-extra-newline

require_relative "../../string_utils"

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   Disallow more than two consecutive blank lines in ERB templates. This rule
        #   enforces a maximum of two blank lines between content to maintain consistent
        #   vertical spacing throughout your templates.
        #
        # Good:
        #   line 1
        #
        #   line 3
        #
        #   <div>
        #    <h1>Title</h1>
        #   </div>
        #
        #   <div>
        #    <h1>Section 1</h1>
        #
        #    <p>Content here</p>
        #   </div>
        #
        #   <div>
        #    <h1>Section 1</h1>
        #
        #
        #    <h1>Section 2</h1>
        #   </div>
        #
        # Bad:
        #   line 1
        #
        #
        #
        #   line 3
        #
        #   <div>
        #    <h1>Title</h1>
        #
        #
        #
        #    <p>Content</p>
        #   </div>
        #
        #   <%= user.name %>
        #
        #
        #
        #
        #   <%= user.email %>
        #
        class NoExtraNewline < SourceRule
          include StringUtils

          def self.rule_name = "erb-no-extra-newline" #: String
          def self.description = "Disallow more than 2 consecutive blank lines in ERB files" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def check_source(source, _context)
            # Find all sequences of 4 or more consecutive newlines
            source.scan(/\n{4,}/) do
              match_data = Regexp.last_match
              match_start = match_data.begin(0)
              match_length = match_data[0].length

              # Calculate how many excess lines (beyond the allowed 3 newlines)
              excess_lines = match_length - 3

              # Create offense at the location of the extra newlines
              # Start at offset + 3 (after the allowed 3 newlines)
              offense_start = match_start + 3
              offense_end = match_start + match_length

              location = location_from_offsets(offense_start, offense_end)

              plural = pluralize(excess_lines, "line")
              message = "Extra blank line detected. Remove #{excess_lines} blank #{plural} " \
                        "to maintain consistent spacing (max 2 allowed)"

              add_offense_with_source_autofix(
                message:,
                location:,
                start_offset: offense_start,
                end_offset: offense_end
              )
            end
          end

          # @rbs override
          def autofix_source(offense, source)
            ctx = offense.autofix_context
            start_offset = ctx.start_offset
            end_offset = ctx.end_offset

            # Verify content at offsets is newlines only
            content = source[start_offset...end_offset]
            return nil unless content&.match?(/\A\n+\z/)

            # Remove the extra newlines
            source[0...start_offset] + source[end_offset..]
          end
        end
      end
    end
  end
end
