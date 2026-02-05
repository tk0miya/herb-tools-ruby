# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that disallows trailing whitespace in ERB tag content.
        #
        # ERB tags should have content that ends with exactly one space before the closing delimiter,
        # not multiple spaces, tabs, or newlines.
        #
        # Good:
        #   <%= value %>
        #   <% statement %>
        #
        # Bad:
        #   <%= value  %>
        #   <% statement\t%>
        #   <%= value
        #   %>
        class NoTrailingWhitespace < VisitorRule
          def self.rule_name #: String
            "erb-no-trailing-whitespace"
          end

          def self.description #: String
            "Disallow trailing whitespace in ERB tag content"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.autocorrectable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            if trailing_whitespace?(node)
              add_offense_with_autofix(
                message: "Remove trailing whitespace in ERB tag",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            content_value = node.content&.value
            return if content_value.nil?

            # Remove all trailing whitespace and add exactly one space
            normalized_content = content_value.rstrip
            return if normalized_content.empty?

            new_content_value = "#{normalized_content} "
            content = copy_token(node.content, content: new_content_value)

            # Create new ERBContentNode with modified content
            new_node = copy_erb_content_node(node, content:)

            # Replace the node in the AST
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def trailing_whitespace?(node) #: bool
            content_value = node.content&.value
            return false if content_value.nil? || content_value.strip.empty?

            # Check if content ends with anything other than exactly one space
            # This includes: multiple spaces, tabs, newlines, or no space at all
            !content_value.match?(/[^ \t\n\r] \z/)
          end
        end
      end
    end
  end
end
