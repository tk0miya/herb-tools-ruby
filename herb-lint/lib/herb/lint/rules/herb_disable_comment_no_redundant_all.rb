# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that detects redundant rule names when `all` is used in herb:disable comments.
      #
      # When `all` is specified in a herb:disable comment, listing specific rule names
      # is redundant since `all` already disables every rule.
      #
      # Good:
      #   <%# herb:disable all %>
      #   <%# herb:disable rule-name %>
      #
      # Bad:
      #   <%# herb:disable all, rule-name %>
      class HerbDisableCommentNoRedundantAll < VisitorRule
        def self.rule_name #: String
          "herb-disable-comment-no-redundant-all"
        end

        def self.description #: String
          "Disallow specific rule names alongside `all` in herb:disable comments"
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
          comment = DirectiveParser.parse_disable_comment_content(content)
          return unless comment&.match

          rule_names = comment.rule_names
          return unless rule_names.include?("all") && rule_names.size > 1

          comment.rule_name_details.each do |detail|
            next if detail.name == "all"

            add_offense(
              message: "Redundant rule name `#{detail.name}` when `all` is already specified",
              location: node.content.location
            )
          end
        end
      end
    end
  end
end
