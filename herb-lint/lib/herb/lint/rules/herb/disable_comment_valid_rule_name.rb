# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/herb-disable-comment-valid-rule-name.ts
# Documentation: https://herb-tools.dev/linter/rules/herb-disable-comment-valid-rule-name

require "did_you_mean"

module Herb
  module Lint
    module Rules
      module HerbDirective
        # Description:
        #   Ensures that all rule names specified in `<%# herb:disable ... %>` comments are valid and exist in the
        #   linter. This catches typos, references to non-existent rules and missing comma between rule names.
        #
        # Good:
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase %>
        #
        #   <DIV class='value'>test</DIV> <%# herb:disable html-tag-name-lowercase, html-attribute-double-quotes %>
        #
        #   <DIV>test</DIV> <%# herb:disable all %>
        #
        # Bad:
        #   <div>test</div> <%# herb:disable this-rule-doesnt-exist %>
        #
        #   <div>test</div> <%# herb:disable html-tag-lowercase %>
        #
        #   <DIV>test</DIV> <%# herb:disable html-tag-name-lowercase, invalid-rule-name %>
        #
        #   <div>test</div> <%# herb:disable html-tag-name-lowercase html-attribute-double-quotes %>
        #
        class DisableCommentValidRuleName < DirectiveRule
          def self.rule_name = "herb-disable-comment-valid-rule-name" #: String
          def self.description = "Disallow unknown rule names in herb:disable comments" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @context: Context

          private

          # @rbs override
          def check_disable_comment(comment)
            return unless comment.match

            valid_names = @context.valid_rule_names
            return if valid_names.empty?

            comment.rule_name_details.each do |detail|
              next if detail.name == "all"
              next if valid_names.include?(detail.name)

              add_offense(
                message: build_message(detail.name, valid_names),
                location: offset_location(comment, detail)
              )
            end
          end

          # Build an offense message, including "did you mean?" suggestion when available.
          #
          # @rbs name: String -- the invalid rule name
          # @rbs valid_names: Array[String] -- the list of valid rule names
          def build_message(name, valid_names) #: String
            suggestion = find_suggestion(name, valid_names)

            if suggestion
              "Unknown rule `#{name}`. Did you mean `#{suggestion}`?"
            else
              "Unknown rule `#{name}`."
            end
          end

          # Find the closest match for a misspelled rule name.
          # Returns a single suggestion or nil if no close match is found.
          #
          # @rbs name: String
          # @rbs valid_names: Array[String]
          def find_suggestion(name, valid_names) #: String?
            checker = DidYouMean::SpellChecker.new(dictionary: valid_names)
            suggestions = checker.correct(name)
            suggestions.first
          end
        end
      end
    end
  end
end
