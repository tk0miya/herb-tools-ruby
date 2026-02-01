# frozen_string_literal: true

require "did_you_mean"

module Herb
  module Lint
    module Rules
      # Meta-rule that detects unknown rule names in herb:disable comments.
      #
      # Uses the list of registered rule names to validate each rule name
      # in the directive. Reports offense with "did you mean?" suggestions
      # for close matches.
      #
      # Good:
      #   <%# herb:disable html-img-require-alt %>
      #
      # Bad:
      #   <%# herb:disable html-img-require-alts %>
      #   <%# herb:disable nonexistent-rule %>
      class HerbDisableCommentValidRuleName < VisitorRule
        def self.rule_name #: String
          "herb-disable-comment-valid-rule-name"
        end

        def self.description #: String
          "Disallow unknown rule names in herb:disable comments"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_content_node(node)
          check_disable_comment(node) if erb_comment?(node)
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def erb_comment?(node) #: bool
          node.tag_opening.value == "<%#"
        end

        # @rbs node: Herb::AST::ERBContentNode
        def check_disable_comment(node) #: void
          content = node.content.value
          comment = DirectiveParser.parse_disable_comment_content(content, content_location: node.content.location)
          return unless comment&.match

          valid_names = @context.valid_rule_names
          return if valid_names.empty?

          comment.rule_name_details.each do |detail|
            next if detail.name == "all"
            next if valid_names.include?(detail.name)

            add_offense(
              message: build_message(detail.name, valid_names),
              location: offset_location(node, detail)
            )
          end
        end

        # Build an offense message, including "did you mean?" suggestions when available.
        #
        # @rbs name: String -- the invalid rule name
        # @rbs valid_names: Array[String] -- the list of valid rule names
        def build_message(name, valid_names) #: String
          suggestions = find_suggestions(name, valid_names)

          if suggestions.empty?
            "Unknown rule `#{name}` in herb:disable comment"
          else
            "Unknown rule `#{name}` in herb:disable comment. Did you mean: #{suggestions.join(', ')}?"
          end
        end

        # Find close matches for a misspelled rule name.
        #
        # @rbs name: String
        # @rbs valid_names: Array[String]
        def find_suggestions(name, valid_names) #: Array[String]
          checker = DidYouMean::SpellChecker.new(dictionary: valid_names)
          checker.correct(name)
        end

        # Compute the source location for a rule name within an ERB content node.
        #
        # @rbs node: Herb::AST::ERBContentNode -- the ERB content node
        # @rbs detail: DirectiveParser::DisableRuleName -- the rule name with offset info
        def offset_location(node, detail) #: Herb::Location
          content_start = node.content.location.start
          line = content_start.line
          column = content_start.column + detail.offset

          start_pos = Herb::Position.new(line, column)
          end_pos = Herb::Position.new(line, column + detail.length)
          Herb::Location.new(start_pos, end_pos)
        end
      end
    end
  end
end
