# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-no-duplicate-rules.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-no-duplicate-rules

module Herb
  module Lint
    module Rules
      # Meta-rule that detects duplicate rule names in herb:disable comments.
      #
      # Listing the same rule name more than once in a single herb:disable
      # comment is redundant and likely a mistake.
      #
      # Good:
      #   <%# herb:disable rule1, rule2 %>
      #
      # Bad:
      #   <%# herb:disable rule1, rule1 %>
      class HerbDisableCommentNoDuplicateRules < DirectiveRule
        def self.rule_name #: String
          "herb-disable-comment-no-duplicate-rules"
        end

        def self.description #: String
          "Disallow duplicate rule names in herb:disable comments"
        end

        def self.default_severity #: String
          "warning"
        end

        private

        # @rbs override
        def check_disable_comment(comment)
          return unless comment.match

          seen = {} #: Hash[String, true]

          comment.rule_name_details.each do |detail|
            if seen.key?(detail.name)
              add_offense(
                message: "Duplicate rule '#{detail.name}' in herb:disable comment",
                location: offset_location(comment, detail)
              )
            else
              seen[detail.name] = true
            end
          end
        end
      end
    end
  end
end
