# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows empty ERB tags.
      #
      # Empty ERB tags (`<% %>` with no content or only whitespace) should be removed.
      #
      # Good:
      #   <% do_something %>
      #   <%= value %>
      #
      # Bad:
      #   <% %>
      #   <%  %>
      #   <%= %>
      class ErbNoEmptyTags < VisitorRule
        def self.rule_name #: String
          "erb-no-empty-tags"
        end

        def self.description #: String
          "Disallow empty ERB tags"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_content_node(node)
          if empty_tag?(node)
            add_offense(
              message: "Remove empty ERB tag",
              location: node.location
            )
          end
          super
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def empty_tag?(node) #: bool
          # An empty tag is one where the content is nil, empty, or only whitespace
          content_value = node.content&.value
          content_value.nil? || content_value.strip.empty?
        end
      end
    end
  end
end
