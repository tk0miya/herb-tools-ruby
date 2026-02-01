# frozen_string_literal: true

module Herb
  module Lint
    module Rules
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
      class HerbDisableCommentMissingRules < VisitorRule
        def self.rule_name #: String
          "herb-disable-comment-missing-rules"
        end

        def self.description #: String
          "Require rule names in herb:disable comments"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_erb_content_node(node)
          check_disable_comment(node) if comment_tag?(node)
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def comment_tag?(node) #: bool
          node.tag_opening.value == "<%#"
        end

        # @rbs node: Herb::AST::ERBContentNode
        def check_disable_comment(node) #: void
          content = node.content.value
          comment = DirectiveParser.parse_disable_comment_content(content, content_location: node.content.location)
          return unless comment
          return unless comment.match
          return unless comment.rule_names.empty?

          add_offense(
            message: "`herb:disable` comment must specify at least one rule name or `all`",
            location: node.location
          )
        end
      end
    end
  end
end
