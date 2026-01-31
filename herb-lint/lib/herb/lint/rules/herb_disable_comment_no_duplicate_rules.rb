# frozen_string_literal: true

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
      class HerbDisableCommentNoDuplicateRules < VisitorRule
        def self.rule_name #: String
          "herb-disable-comment-no-duplicate-rules"
        end

        def self.description #: String
          "Disallow duplicate rule names in herb:disable comments"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_content_node(node)
          check_duplicate_rules(node) if erb_comment?(node)
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def erb_comment?(node) #: bool
          node.tag_opening.value == "<%#"
        end

        # @rbs node: Herb::AST::ERBContentNode
        def check_duplicate_rules(node) #: void
          content = node.content.value
          comment = DirectiveParser.parse_disable_comment_content(content)
          return unless comment
          return unless comment.match

          seen = {} #: Hash[String, true]

          comment.rule_name_details.each do |detail|
            if seen.key?(detail.name)
              add_offense(
                message: "Duplicate rule '#{detail.name}' in herb:disable comment",
                location: offset_location(node, detail)
              )
            else
              seen[detail.name] = true
            end
          end
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
