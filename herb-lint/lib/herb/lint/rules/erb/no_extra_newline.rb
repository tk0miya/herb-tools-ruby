# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-extra-newline.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-extra-newline

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
        class NoExtraNewline < Base
          def self.rule_name #: String
            "erb-no-extra-newline"
          end

          def self.description #: String
            "Disallow more than 2 consecutive blank lines in ERB files"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def check(_document, context)
            @offenses = []
            @context = context
            @source = context.source

            # Find all sequences of 4 or more consecutive newlines
            @source.scan(/\n{4,}/) do
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

              plural = excess_lines == 1 ? "line" : "lines"
              message = "Extra blank line detected. Remove #{excess_lines} blank #{plural} " \
                        "to maintain consistent spacing (max 2 allowed)"

              add_offense(message:, location:)
            end

            @offenses
          end

          private

          # @rbs @source: String

          # Create a location object from byte offsets.
          # @rbs start_offset: Integer
          # @rbs end_offset: Integer
          def location_from_offsets(start_offset, end_offset) #: Herb::Location
            start_pos = position_from_offset(start_offset)
            end_pos = position_from_offset(end_offset)

            Herb::Location.new(
              Herb::Position.new(start_pos[:line], start_pos[:column]),
              Herb::Position.new(end_pos[:line], end_pos[:column])
            )
          end

          # Convert byte offset to line and column position (0-indexed).
          # @rbs offset: Integer
          def position_from_offset(offset) #: Hash[Symbol, Integer]
            line = 0
            column = 0
            current_offset = 0

            @source.each_char do |char|
              break if current_offset >= offset

              if char == "\n"
                line += 1
                column = 0
              else
                column += 1
              end
              current_offset += 1
            end

            { line:, column: }
          end
        end
      end
    end
  end
end
