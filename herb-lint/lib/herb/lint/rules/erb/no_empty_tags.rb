# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-no-empty-tags.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-no-empty-tags

module Herb
  module Lint
    module Rules
      module Erb
        # ERB tag should not be empty. Remove empty ERB tags or add content.
        #
        # Good:
        #   <% do_something %>
        #   <%= value %>
        #
        # Bad:
        #   <% %>
        #   <%  %>
        #   <%= %>
        class NoEmptyTags < VisitorRule
          def self.rule_name #: String
            "erb-no-empty-tags"
          end

          def self.description #: String
            "Disallow empty ERB tags"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def visit_erb_content_node(node)
            if empty_tag?(node)
              add_offense(
                message: "ERB tag should not be empty. Remove empty ERB tags or add content.",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::ERBContentNode
          def empty_tag?(node) #: bool
            return false if node.content.nil?
            return false if node.tag_closing&.value == ""

            node.content.value.strip.empty?
          end
        end
      end
    end
  end
end
