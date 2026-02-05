# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that disallows space before closing ERB tag delimiter.
        #
        # ERB tags should not have whitespace immediately before the closing `%>`.
        #
        # Good:
        #   <% value %>
        #   <%= value %>
        #   <% value -%>
        #
        # Bad:
        #   <% value  %>
        #   <%= value  %>
        #   <% value  -%>
        class NoSpaceBeforeClose < VisitorRule
          def self.rule_name #: String
            "erb-no-space-before-close"
          end

          def self.description #: String
            "Disallow space before closing ERB tag delimiter"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.autocorrectable? #: bool
            true
          end

          # @rbs override
          def visit_erb_content_node(node)
            if space_before_close?(node)
              add_offense_with_autofix(
                message: "Remove space before closing `%>`",
                location: node.location,
                node:
              )
            end
            super
          end

          # @rbs override
          def autofix(node, parse_result)
            content_value = node.content&.value
            return false if content_value.nil?

            # Remove extra trailing whitespace, keeping only one space if content exists
            # We need to preserve the single trailing space for proper ERB formatting
            new_content_value = if content_value.strip.empty?
                                  content_value.rstrip
                                else
                                  content_value.sub(/[ \t]+\z/, " ")
                                end

            new_content = copy_token(node.content, content: new_content_value)

            # Create new ERBContentNode with trimmed content
            new_node = copy_erb_content_node(node, content: new_content)

            # Replace the node in the AST
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def space_before_close?(node) #: bool
            content_value = node.content&.value
            return false if content_value.nil? || content_value.empty?
            return false if comment_tag?(node)

            # Check if content ends with multiple spaces or tabs (not just a single space)
            # Single trailing space is expected (per erb-require-whitespace-inside-tags)
            # but multiple trailing spaces or tabs are not allowed
            content_value.match?(/[ \t]{2,}\z/) || content_value.match?(/\t\z/)
          end

          # @rbs node: Herb::AST::ERBContentNode
          def comment_tag?(node) #: bool
            node.tag_opening.value == "<%#"
          end
        end
      end
    end
  end
end
