# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-malformed.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-malformed

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Meta-rule that detects syntactically malformed `herb:disable` directive comments.
        #
        # Detects:
        # - Missing space after `herb:disable` prefix (e.g. `herb:disablerule-name`)
        # - Leading commas in the rule list (e.g. `herb:disable ,rule-name`)
        # - Trailing commas in the rule list (e.g. `herb:disable rule-name,`)
        # - Consecutive commas in the rule list (e.g. `herb:disable rule1,,rule2`)
        class DisableCommentMalformed < DirectiveRule
          def self.rule_name #: String
            "herb-disable-comment-malformed"
          end

          def self.description #: String
            "Detect malformed herb:disable comments"
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          private

          # @rbs override
          def check_disable_comment(comment)
            unless comment.match
              add_offense(
                message: "Malformed herb:disable comment: missing space after `herb:disable`",
                location: comment.content_location
              )
              return
            end

            check_comma_issues(comment)
          end

          # @rbs comment: DirectiveParser::DisableComment
          def check_comma_issues(comment) #: void
            rules_string = comment.rules_string
            return if rules_string.nil? || rules_string.empty?

            if rules_string.match?(/\A\s*,/)
              add_offense(
                message: "Malformed herb:disable comment: leading comma in rule list",
                location: comment.content_location
              )
            end

            if rules_string.match?(/,\s*\z/)
              add_offense(
                message: "Malformed herb:disable comment: trailing comma in rule list",
                location: comment.content_location
              )
            end

            return unless rules_string.match?(/,\s*,/)

            add_offense(
              message: "Malformed herb:disable comment: consecutive commas in rule list",
              location: comment.content_location
            )
          end
        end
      end
    end
  end
end
