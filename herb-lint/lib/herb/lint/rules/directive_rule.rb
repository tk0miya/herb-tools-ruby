# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Base class for rules that inspect pre-parsed directive comments.
      # Unlike VisitorRule, this class does not traverse the AST. Instead,
      # it iterates over the directives already collected by DirectiveParser
      # and made available via Context#directives.
      #
      # Subclasses should override `check_disable_comment` to inspect each
      # DisableComment. Use `add_offense` to report violations.
      #
      # Example:
      #   class MyDirectiveRule < DirectiveRule
      #     def self.rule_name = "my-directive-rule"
      #     def self.description = "My custom directive rule"
      #
      #     private
      #
      #     def check_disable_comment(comment)
      #       if some_condition?(comment)
      #         add_offense(message: "Explanation", location: comment.content_location)
      #       end
      #     end
      #   end
      class DirectiveRule < Base
        # Check the document for rule violations by iterating over parsed directives.
        # @rbs override
        def check(document, context) # rubocop:disable Lint/UnusedMethodArgument
          @offenses = []
          @context = context

          context.directives.disable_comments.each_value do |comment|
            check_disable_comment(comment)
          end

          @offenses
        end

        private

        # Compute the source location for a rule name within a disable comment.
        #
        # @rbs comment: DirectiveParser::DisableComment -- the disable comment
        # @rbs detail: DirectiveParser::DisableRuleName -- the rule name with offset info
        def offset_location(comment, detail) #: Herb::Location
          content_start = comment.content_location.start
          line = content_start.line
          column = content_start.column + detail.offset

          start_pos = Herb::Position.new(line, column)
          end_pos = Herb::Position.new(line, column + detail.length)
          Herb::Location.new(start_pos, end_pos)
        end

        # Check a single disable comment for rule violations.
        # Subclasses must override this method.
        #
        # @rbs comment: DirectiveParser::DisableComment -- the disable comment to check
        def check_disable_comment(comment) #: void
          raise NotImplementedError, "#{self.class.name} must implement #check_disable_comment"
        end
      end
    end
  end
end
