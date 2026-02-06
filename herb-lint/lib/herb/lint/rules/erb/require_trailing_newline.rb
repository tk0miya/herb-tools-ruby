# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-trailing-newline.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-require-trailing-newline

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that requires a trailing newline at the end of the file.
        #
        # Files should end with exactly one newline character.
        #
        # Good:
        #   <div>content</div>
        #   [newline here]
        #
        # Bad:
        #   <div>content</div>[no newline]
        #
        # Also Bad:
        #   <div>content</div>
        #   [multiple newlines]
        class RequireTrailingNewline < VisitorRule
          def self.rule_name #: String
            "erb-require-trailing-newline"
          end

          def self.description #: String
            "Require a trailing newline at the end of the file"
          end

          def self.default_severity #: String
            "error"
          end

          # @rbs override
          def visit_document_node(node)
            last_child = node.children.last

            case last_child
            when nil
              # Empty file - no offense
              return super
            when Herb::AST::HTMLTextNode
              # Last node is a text node - check if it ends with newline
              check_text_node_trailing_newline(last_child)
            else
              # Last node is not a text node - missing trailing newline
              add_offense(
                message: "File must end with a newline",
                location: last_child.location
              )
            end

            super
          end

          private

          # @rbs @context: Context

          # @rbs node: Herb::AST::HTMLTextNode
          def check_text_node_trailing_newline(node) #: void
            content = node.content

            if !content.end_with?("\n")
              # No trailing newline
              add_offense(
                message: "File must end with a newline",
                location: node.location
              )
            elsif content.end_with?("\n\n")
              # Multiple trailing newlines
              add_offense(
                message: "File must end with exactly one newline",
                location: node.location
              )
            end
          end
        end
      end
    end
  end
end
