# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/erb-require-trailing-newline.ts
# Documentation: https://herb-tools.dev/linter/rules/erb-require-trailing-newline

module Herb
  module Lint
    module Rules
      module Erb
        # Description:
        #   This rule enforces that all HTML+ERB template files end with exactly one trailing newline character.
        #   This is a formatting convention widely adopted across many languages and tools.
        #
        # Good:
        #   <%= render partial: "header" %>
        #   <%= render partial: "footer" %>
        #
        #   (Note: File ends with a newline character)
        #
        # Bad:
        #   <%= render partial: "header" %>
        #   <%= render partial: "footer" %>
        #
        #   (Note: File ends without a trailing newline)
        #
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

          def self.safe_autofixable? #: bool
            true
          end

          def self.unsafe_autofixable? #: bool
            false
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
              add_offense_with_autofix(
                message: "File must end with a newline",
                location: last_child.location,
                node:
              )
            end

            super
          end

          # @rbs node: Herb::AST::DocumentNode | Herb::AST::HTMLTextNode
          # @rbs parse_result: Herb::ParseResult
          def autofix(node, parse_result) #: bool
            case node
            when Herb::AST::HTMLTextNode
              # Fix trailing newlines in the text node
              fix_text_node_trailing_newline(node, parse_result)
            when Herb::AST::DocumentNode
              # Append a text node with newline
              append_trailing_newline_text_node(node)
            else
              false
            end
          end

          private

          # @rbs @context: Context

          # @rbs node: Herb::AST::HTMLTextNode
          def check_text_node_trailing_newline(node) #: void
            content = node.content

            if !content.end_with?("\n")
              # No trailing newline
              add_offense_with_autofix(
                message: "File must end with a newline",
                location: node.location,
                node:
              )
            elsif content.end_with?("\n\n")
              # Multiple trailing newlines
              add_offense_with_autofix(
                message: "File must end with exactly one newline",
                location: node.location,
                node:
              )
            end
          end

          # Fix trailing newlines in an HTMLTextNode.
          # @rbs node: Herb::AST::HTMLTextNode
          # @rbs parse_result: Herb::ParseResult
          def fix_text_node_trailing_newline(node, parse_result) #: bool
            # Remove all trailing newlines and add exactly one
            new_content = "#{node.content.sub(/\n+\z/, '')}\n"
            new_text_node = copy_html_text_node(node, content: new_content)
            replace_node(parse_result, node, new_text_node)
          end

          # Append a text node with trailing newline when the last node is not an HTMLTextNode.
          # @rbs document_node: Herb::AST::DocumentNode
          def append_trailing_newline_text_node(document_node) #: bool # rubocop:disable Naming/PredicateMethod
            last_child = document_node.children.last
            return false if last_child.nil?

            location = Herb::Location.new(
              last_child.location.end,
              Herb::Position.new(last_child.location.end.line, last_child.location.end.column + 1)
            )

            new_text_node = Herb::AST::HTMLTextNode.new(
              "html-text",
              location,
              [],
              +"\n"
            )

            document_node.children << new_text_node
            true
          end
        end
      end
    end
  end
end
