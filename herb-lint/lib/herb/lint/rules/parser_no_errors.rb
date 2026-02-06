# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/parser-no-errors.ts
# Documentation: https://herb-tools.dev/linter/rules/parser-no-errors

module Herb
  module Lint
    module Rules
      # Rule that reports parser errors as lint offenses.
      #
      # When the Herb parser encounters syntax errors in ERB templates,
      # this rule surfaces them as lint violations so users see all issues
      # in one report.
      #
      # This rule is special in that it doesn't implement a check method.
      # Instead, the Linter class directly creates offenses for parser errors
      # using this rule's metadata.
      #
      # Examples of parser errors:
      #   - Unclosed ERB tags: <%= unclosed
      #   - Unclosed HTML tags: <div><span>unclosed
      #   - Malformed ERB syntax
      class ParserNoErrors < Base
        def self.rule_name #: String
          "parser-no-errors"
        end

        def self.description #: String
          "Report parser errors as lint offenses"
        end

        def self.default_severity #: String
          "error"
        end

        # This method is not called by the Linter.
        # Parser errors are detected and reported directly by the Linter class
        # before normal rule checking begins.
        #
        # @rbs override
        def check(_document, _context) #: Array[Offense]
          []
        end
      end
    end
  end
end
