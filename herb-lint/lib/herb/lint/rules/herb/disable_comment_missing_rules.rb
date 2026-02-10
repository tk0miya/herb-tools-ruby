# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-missing-rules.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-missing-rules

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Rule that detects `herb:disable` comments with no rule names specified.
        #
        # A `herb:disable` comment must specify at least one rule name or `all`.
        # An empty `herb:disable` comment has no effect and is likely a mistake.
        #
        # Good:
        #   <%# herb:disable rule-name %>
        #   <%# herb:disable all %>
        #
        # Bad:
        #   <%# herb:disable %>
        class DisableCommentMissingRules < DirectiveRule
          def self.rule_name #: String
            "herb-disable-comment-missing-rules"
          end

          def self.description #: String
            "Require rule names in herb:disable comments"
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
            return unless comment.match
            return unless comment.rule_names.empty?

            add_offense(
              message: "`herb:disable` comment must specify at least one rule name or `all`",
              location: comment.content_location
            )
          end
        end
      end
    end
  end
end
