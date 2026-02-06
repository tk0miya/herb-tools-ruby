# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-strict-locals-required.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-strict-locals-required

module Herb
  module Lint
    module Rules
      # Rule that requires strict_locals magic comment in partial files.
      #
      # Partial files (files whose basename starts with underscore) should have
      # a strict_locals magic comment at the top of the file to declare local variables.
      #
      # Good:
      #   <%# locals: (name: String) %>
      #   <div><%= name %></div>
      #
      # Bad (missing strict_locals in partial):
      #   <div><%= name %></div>
      class ErbStrictLocalsRequired < VisitorRule
        def self.rule_name #: String
          "erb-strict-locals-required"
        end

        def self.description #: String
          "Require strict_locals magic comment in partial files"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs @locals_definition_found: bool

        # @rbs override
        def on_new_investigation #: void
          super
          @locals_definition_found = false
        end

        # @rbs override
        def visit_document_node(node)
          return super unless partial_file? # Skip checking if not a partial

          super # Traverse the tree to find locals definition

          return if @locals_definition_found

          add_offense(
            message: "Partial files must have a strict_locals magic comment (<%# locals: ... %>)",
            location: node.location
          )
        end

        # @rbs override
        def visit_erb_content_node(node)
          @locals_definition_found = true if erb_comment_with_locals?(node)
          super
        end

        # @rbs override
        def visit_child_nodes(node)
          return if @locals_definition_found # Stop traversal once found

          super
        end

        private

        # Check if the current file is a partial (basename starts with underscore)
        def partial_file? #: bool
          file_path = @context.file_path
          basename = File.basename(file_path)
          basename.start_with?("_")
        end

        # Check if an ERB content node is a comment with locals definition
        # @rbs node: Herb::AST::ERBContentNode
        def erb_comment_with_locals?(node) #: bool
          return false unless node.tag_opening.value == "<%#"

          content = node.content&.value
          return false if content.nil?

          # Match "locals:" followed by optional whitespace and parentheses
          content.match?(/\blocals\s*:/)
        end
      end
    end
  end
end
