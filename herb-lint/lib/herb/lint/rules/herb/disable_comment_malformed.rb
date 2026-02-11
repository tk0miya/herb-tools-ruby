# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-malformed.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-malformed

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Description:
        #   Detects malformed `<%# herb:disable ... %>` comments that have syntax errors like trailing commas,
        #   leading commas, consecutive commas, or missing spaces after `herb:disable`.
        #
        # Good:
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase %>
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-attribute-double-quotes %>
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase , html-attribute-double-quotes %>
        #
        #   <DIV>test</DIV> <%# herb:disable all %>
        #
        # Bad:
        #   <div>test</div> <%# herb:disable html-tag-name-lowercase, %>
        #
        #   <div>test</div> <%# herb:disable , html-tag-name-lowercase %>
        #
        #   <div>test</div> <%# herb:disable html-tag-name-lowercase,, html-attribute-double-quotes %>
        #
        #   <div>test</div> <%# herb:disable html-tag-name-localhost,, %>
        #
        #   <DIV>test</DIV> <%# herb:disableall %>
        #
        #   <DIV>test</DIV> <%# herb:disablehtml-tag-name-lowercase %>
        #
        class DisableCommentMalformed < DirectiveRule
          def self.rule_name = "herb-disable-comment-malformed" #: String
          def self.description = "Detect malformed herb:disable comments" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

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
