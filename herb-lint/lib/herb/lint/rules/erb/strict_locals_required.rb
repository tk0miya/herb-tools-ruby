# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-strict-locals-required.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-strict-locals-required

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   The rule requires that every Rails partial template includes a strict locals
        #   declaration comment using this syntax:
        #
        #   ```erb
        #   <%# locals: () %>
        #   ```
        #
        #   A partial is any template whose filename begins with an underscore (e.g.
        #   `_card.html.erb`).
        #
        # Good:
        #   Partial with required keyword argument:
        #   ```erb
        #   <%# locals: (user:) %>
        #
        #   <div class="user-card">
        #     <%= user.name %>
        #   </div>
        #   ```
        #
        #   Partial with keyword argument and default:
        #   ```erb
        #   <%# locals: (user:, admin: false) %>
        #
        #   <div class="user-card">
        #     <%= user.name %>
        #
        #     <% if admin %>
        #     <span class="badge">Admin</span>
        #     <% end %>
        #   </div>
        #   ```
        #
        #   Partial with no locals (empty declaration):
        #   ```erb
        #   <%# locals: () %>
        #
        #   <p>Static content only</p>
        #   ```
        #
        # Bad:
        #   Partial without strict locals declaration:
        #   ```erb
        #   <div class="user-card">
        #     <%= user.name %>
        #   </div>
        #   ```
        #
        class StrictLocalsRequired < VisitorRule
          def self.rule_name = "erb-strict-locals-required" #: String
          def self.description = "Require strict_locals magic comment in partial files" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

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
              message: "Partial is missing a strict locals declaration. " \
                       "Add `<%# locals: (...) %>` at the top of the file.",
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
end
