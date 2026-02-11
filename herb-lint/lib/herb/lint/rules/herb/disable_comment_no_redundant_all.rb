# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-no-redundant-all.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-no-redundant-all

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Description:
        #   Prevents using `all` together with specific rule names in `<%# herb:disable ... %>`
        #   comments, as this is redundant.
        #
        # Good:
        #   <DIV>test</DIV> <%# herb:disable all %>
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-attribute-double-quotes %>
        #
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase %>
        #
        # Bad:
        #   <DIV>test</DIV> <%# herb:disable all, html-tag-name-lowercase %>
        #
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase, all, html-attribute-double-quotes %>
        #
        #   <DIV>test</DIV> <%# herb:disable all, all %>
        #
        class DisableCommentNoRedundantAll < DirectiveRule
          def self.rule_name = "herb-disable-comment-no-redundant-all" #: String
          def self.description = "Disallow specific rule names alongside `all` in herb:disable comments" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          private

          # @rbs override
          def check_disable_comment(comment)
            return unless comment.match

            rule_names = comment.rule_names
            return unless rule_names.include?("all") && rule_names.size > 1

            first_all_seen = false
            comment.rule_name_details.each do |detail|
              case detail.name
              when "all"
                report_redundant_rule(detail.name, comment) if first_all_seen
                first_all_seen = true
              else
                report_redundant_rule(detail.name, comment)
              end
            end
          end

          # @rbs rule_name: String, comment: HerbDirective::DisableComment -- return: void
          def report_redundant_rule(rule_name, comment)
            add_offense(
              message: "Redundant rule name `#{rule_name}` when `all` is already specified",
              location: comment.content_location
            )
          end
        end
      end
    end
  end
end
