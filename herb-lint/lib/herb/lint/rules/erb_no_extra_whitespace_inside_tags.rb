# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows extra whitespace inside ERB tag delimiters.
      #
      # ERB tags should have exactly one space between the delimiter and content,
      # not multiple spaces.
      #
      # Good:
      #   <% value %>
      #   <%= value %>
      #
      # Bad:
      #   <%  value  %>
      #   <%=  value  %>
      class ErbNoExtraWhitespaceInsideTags < VisitorRule
        def self.rule_name #: String
          "erb-no-extra-whitespace-inside-tags"
        end

        def self.description #: String
          "Disallow extra whitespace inside ERB tag delimiters"
        end

        def self.default_severity #: String
          "warning"
        end

        def self.autocorrectable? #: bool
          true
        end

        # @rbs override
        def visit_erb_content_node(node)
          if extra_whitespace?(node)
            add_offense_with_autofix(
              message: "Remove extra whitespace inside ERB tag",
              location: node.location,
              node:
            )
          end
          super
        end

        # @rbs override
        def autofix(node, parse_result)
          new_content_value = node.content.value.gsub(/\A[ \t]{2,}/, " ").gsub(/[ \t]{2,}\z/, " ")
          content = copy_token(node.content, content: new_content_value)
          new_node = copy_erb_content_node(node, content:)
          replace_node(parse_result, node, new_node)
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def extra_whitespace?(node) #: bool
          content_value = node.content&.value
          return false if content_value.nil? || content_value.strip.empty?

          # Check for 2+ spaces/tabs at the beginning or end
          leading_extra_whitespace?(content_value) || trailing_extra_whitespace?(content_value)
        end

        # @rbs content: String
        def leading_extra_whitespace?(content) #: bool
          # Match 2 or more whitespace characters at the start
          content.match?(/\A[ \t]{2,}/)
        end

        # @rbs content: String
        def trailing_extra_whitespace?(content) #: bool
          # Match 2 or more whitespace characters at the end
          content.match?(/[ \t]{2,}\z/)
        end
      end
    end
  end
end
