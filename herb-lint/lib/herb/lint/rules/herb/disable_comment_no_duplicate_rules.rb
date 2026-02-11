# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-no-duplicate-rules.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-no-duplicate-rules

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Description:
        #   Prevents listing the same rule name multiple times in a `<%# herb:disable ... %>` comment.
        #
        # Good:
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-attribute-double-quotes %>
        #
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase %>
        #
        #   <DIV>test</DIV> <%# herb:disable all %>
        #
        # Bad:
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase, html-tag-name-lowercase %>
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-attribute-double-quotes, html-tag-name-lowercase, html-tag-name-lowercase %> # rubocop:disable Layout/LineLength
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-tag-name-lowercase, html-attribute-double-quotes, html-attribute-double-quotes %> # rubocop:disable Layout/LineLength
        #
        #   <DIV>test</DIV> <%# herb:disable all, all %>
        #
        class DisableCommentNoDuplicateRules < DirectiveRule
          def self.rule_name = "herb-disable-comment-no-duplicate-rules" #: String
          def self.description = "Disallow duplicate rule names in herb:disable comments" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          private

          # @rbs override
          def check_disable_comment(comment)
            return unless comment.match

            seen = {} #: Hash[String, true]

            comment.rule_name_details.each do |detail|
              if seen.key?(detail.name)
                add_offense(
                  message: "Duplicate rule `#{detail.name}` in `herb:disable` comment. Remove the duplicate.",
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
end
