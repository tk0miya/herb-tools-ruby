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
          def check_source(source, _context) #: void
            return if source.empty?

            if !source.end_with?("\n")
              check_no_trailing_newline(source)
            elsif source.end_with?("\n\n")
              check_multiple_trailing_newlines(source)
            end
          end

          # @rbs override
          # @rbs offense: Offense
          # @rbs source: String
          def autofix_source(_offense, source) #: String?
            "#{source.rstrip}\n"
          end

          private

          # @rbs source: String
          def check_no_trailing_newline(source) #: void
            add_offense_with_source_autofix(
              message: "File must end with a newline",
              location: location_from_offsets(source.length, source.length),
              start_offset: source.length,
              end_offset: source.length
            )
          end

          # @rbs source: String
          def check_multiple_trailing_newlines(source) #: void
            trailing_newlines = source.match(/\n+\z/)&.[](0) || ""
            start_offset = source.length - trailing_newlines.length + 1
            add_offense_with_source_autofix(
              message: "File must end with exactly one newline",
              location: location_from_offsets(start_offset, source.length),
              start_offset:,
              end_offset: source.length
            )
          end
        end
      end
    end
  end
end
