# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-no-redundant-all.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-no-redundant-all

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Rule that detects redundant rule names when `all` is used in herb:disable comments.
        #
        # When `all` is specified in a herb:disable comment, listing specific rule names
        # is redundant since `all` already disables every rule.
        #
        # Good:
        #   <%# herb:disable all %>
        #   <%# herb:disable rule-name %>
        #
        # Bad:
        #   <%# herb:disable all, rule-name %>
        class DisableCommentNoRedundantAll < DirectiveRule
          def self.rule_name #: String
            "herb-disable-comment-no-redundant-all"
          end

          def self.description #: String
            "Disallow specific rule names alongside `all` in herb:disable comments"
          end

          def self.default_severity #: String
            "warning"
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

            rule_names = comment.rule_names
            return unless rule_names.include?("all") && rule_names.size > 1

            comment.rule_name_details.each do |detail|
              next if detail.name == "all"

              add_offense(
                message: "Redundant rule name `#{detail.name}` when `all` is already specified",
                location: comment.content_location
              )
            end
          end
        end
      end
    end
  end
end
