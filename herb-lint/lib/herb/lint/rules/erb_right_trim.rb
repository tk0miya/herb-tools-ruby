# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-right-trim.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-right-trim

module Herb
  module Lint
    module Rules
      # Rule that detects the obscure `=%>` right-trim syntax in ERB tags.
      #
      # The `=%>` syntax is obscure and not well-supported in most ERB engines.
      # Use `-%>` instead for right-trimming whitespace after ERB tags.
      #
      # Bad:
      #   <% if condition =%>
      #     <p>Content</p>
      #   <% end =%>
      #
      # Good:
      #   <% if condition -%>
      #     <p>Content</p>
      #   <% end -%>
      class ErbRightTrim < VisitorRule
        def self.rule_name #: String
          "erb-right-trim"
        end

        def self.description #: String
          "Use `-%>` instead of `=%>` for right-trimming"
        end

        def self.default_severity #: String
          "error"
        end

        # Check each ERB node for the obscure =%> syntax
        # @rbs override
        def visit_child_nodes(node)
          check_erb_node(node) if node.class.name.start_with?("Herb::AST::ERB")
          super
        end

        private

        # @rbs node: untyped
        def check_erb_node(node) #: void
          return unless node.tag_closing
          return unless node.tag_closing.value == "=%>"

          add_offense(
            message: "Use `-%>` instead of `=%>` for right-trimming. " \
                     "The `=%>` syntax is obscure and not well-supported in most ERB engines.",
            location: node.tag_closing.location
          )
        end
      end
    end
  end
end
