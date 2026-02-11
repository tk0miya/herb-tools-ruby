# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-trailing-newline.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-require-trailing-newline

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   This rule enforces that all HTML+ERB template files end with exactly one trailing newline character.
        #   This is a formatting convention widely adopted across many languages and tools.
        #
        # Good:
        #   <%= render partial: "header" %>
        #   <%= render partial: "footer" %>
        #
        #   (Note: File ends with a newline character)
        #
        # Bad:
        #   <%= render partial: "header" %>
        #   <%= render partial: "footer" %>
        #
        #   (Note: File ends without a trailing newline)
        #
        class RequireTrailingNewline < SourceRule
          def self.rule_name = "erb-require-trailing-newline" #: String
          def self.description = "Require a trailing newline at the end of the file" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = true #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def check_source(source, _context)
            return if source.empty?

            eof_offset = source.length

            if !source.end_with?("\n")
              # No trailing newline - offense at EOF position
              add_offense_with_source_autofix(
                message: "File must end with a newline",
                location: location_from_offsets(eof_offset, eof_offset),
                start_offset: eof_offset,
                end_offset: eof_offset
              )
            elsif source.end_with?("\n\n")
              # Multiple trailing newlines - find where trailing whitespace starts
              stripped = source.rstrip
              trailing_start = stripped.length

              add_offense_with_source_autofix(
                message: "File must end with exactly one newline",
                location: location_from_offsets(trailing_start, eof_offset),
                start_offset: trailing_start,
                end_offset: eof_offset
              )
            end
          end

          # @rbs offense: Offense
          # @rbs source: String
          def autofix_source(_offense, source) #: String?
            # Remove all trailing whitespace and add exactly one newline
            "#{source.rstrip}\n"
          end
        end
      end
    end
  end
end
