# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Meta-rule that detects syntactically malformed `herb:disable` directive comments.
      #
      # Detects:
      # - Missing space after `herb:disable` prefix (e.g. `herb:disablerule-name`)
      # - Leading commas in the rule list (e.g. `herb:disable ,rule-name`)
      # - Trailing commas in the rule list (e.g. `herb:disable rule-name,`)
      # - Consecutive commas in the rule list (e.g. `herb:disable rule1,,rule2`)
      class HerbDisableCommentMalformed < VisitorRule
        def self.rule_name #: String
          "herb-disable-comment-malformed"
        end

        def self.description #: String
          "Detect malformed herb:disable comments"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_erb_content_node(node)
          check_erb_comment(node) if node.tag_opening.value == "<%#"
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def check_erb_comment(node) #: void
          content = node.content.value
          parsed = DirectiveParser.parse_disable_comment_content(content, content_location: node.content.location)
          return unless parsed

          unless parsed.match
            add_offense(
              message: "Malformed herb:disable comment: missing space after `herb:disable`",
              location: node.location
            )
            return
          end

          check_comma_issues(parsed, node)
        end

        # @rbs parsed: DirectiveParser::DisableComment
        # @rbs node: Herb::AST::ERBContentNode
        def check_comma_issues(parsed, node) #: void
          rules_string = parsed.rules_string
          return if rules_string.nil? || rules_string.empty?

          if rules_string.match?(/\A\s*,/)
            add_offense(
              message: "Malformed herb:disable comment: leading comma in rule list",
              location: node.location
            )
          end

          if rules_string.match?(/,\s*\z/)
            add_offense(
              message: "Malformed herb:disable comment: trailing comma in rule list",
              location: node.location
            )
          end

          return unless rules_string.match?(/,\s*,/)

          add_offense(
            message: "Malformed herb:disable comment: consecutive commas in rule list",
            location: node.location
          )
        end
      end
    end
  end
end
