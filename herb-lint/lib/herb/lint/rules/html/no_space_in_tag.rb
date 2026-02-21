# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-space-in-tag.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-space-in-tag

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows extra whitespace inside HTML tags,
        # including spaces between the tag name and attributes,
        # between consecutive attributes, trailing spaces before `>`,
        # incorrect spacing around `/>`, and multiline indentation.
        class NoSpaceInTag < VisitorRule
          EXTRA_SPACE_NO_SPACE = "Extra space detected where there should be no space."
          EXTRA_SPACE_SINGLE_SPACE = "Extra space detected where there should be a single space."
          EXTRA_SPACE_SINGLE_BREAK = "Extra space detected where there should be a single space or a single line break."
          NO_SPACE_SINGLE_SPACE = "No space detected where there should be a single space."

          def self.rule_name = "html-no-space-in-tag" #: String
          def self.description = "Disallow extra whitespace inside HTML tags" #: String
          def self.default_severity = "warning" #: String
          # TODO: enable and fix autofix (matching TypeScript implementation)
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_open_tag_node(node)
            if node.location.start.line == node.location.end.line
              check_single_line_open_tag(node)
            else
              check_multiline_open_tag(node)
            end
            super
          end

          # @rbs override
          def visit_html_close_tag_node(node)
            check_close_tag(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLOpenTagNode
          def self_closing?(node) #: bool
            node.tag_closing&.value == "/>"
          end

          # Check all whitespace nodes in a single-line tag
          # Matches TypeScript implementation: directly check whitespace node content
          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_single_line_open_tag(node) #: void
            check_trailing_whitespace_existence(node) if self_closing?(node)

            whitespace_nodes = node.children.select { _1.is_a?(Herb::AST::WhitespaceNode) }
            whitespace_nodes.each do |ws|
              if ws == node.children.last
                check_trailing_whitespace(node, ws)
              else
                # Non-trailing whitespace should be exactly 1 character
                check_non_trailing_whitespace(node, ws)
              end
            end
          end

          # Check if trailing whitespace exists for self-closing tags
          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_trailing_whitespace_existence(node) #: void
            last_child = node.children.last
            return if last_child.is_a?(Herb::AST::WhitespaceNode)

            # Self-closing tag needs space before />
            add_offense(message: NO_SPACE_SINGLE_SPACE, location: node.tag_closing.location)
          end

          # Check non-trailing whitespace (between elements)
          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs whitespace: Herb::AST::WhitespaceNode
          def check_non_trailing_whitespace(node, whitespace) #: void # rubocop:disable Lint/UnusedMethodArgument
            return if whitespace.value.value.length == 1

            add_offense(message: EXTRA_SPACE_SINGLE_SPACE, location: whitespace.location)
          end

          # Check trailing whitespace (before closing bracket)
          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs whitespace: Herb::AST::WhitespaceNode
          def check_trailing_whitespace(node, whitespace) #: void
            # Self-closing tags need exactly 1 space before />
            return if self_closing?(node) && whitespace.value.value.length == 1

            # Regular tags should have no trailing whitespace, or self-closing with wrong spacing
            add_offense(message: EXTRA_SPACE_NO_SPACE, location: whitespace.location)
          end

          # Check multiline open tag by inspecting whitespace nodes directly
          # Matches TypeScript implementation: iterate through whitespace nodes,
          # track consecutive newlines, and validate indentation
          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_multiline_open_tag(node) #: void
            whitespace_nodes = node.children.select { _1.is_a?(Herb::AST::WhitespaceNode) }
            previous_whitespace = nil

            whitespace_nodes.each_with_index do |whitespace, index|
              content = whitespace_content(whitespace)
              next unless content

              if consecutive_newlines?(content, previous_whitespace)
                add_offense(message: EXTRA_SPACE_SINGLE_BREAK, location: whitespace.location)
                previous_whitespace = whitespace
                next
              end

              check_indentation(whitespace, index, whitespace_nodes.size, node) if non_newline_whitespace?(content)

              previous_whitespace = whitespace
            end
          end

          # Get whitespace content value
          # @rbs whitespace: Herb::AST::WhitespaceNode
          def whitespace_content(whitespace) #: String?
            whitespace.value&.value
          end

          # Check if content has consecutive newlines
          # @rbs content: String
          # @rbs previous_whitespace: Herb::AST::WhitespaceNode?
          def consecutive_newlines?(content, previous_whitespace) #: bool
            return previous_whitespace&.value&.value == "\n" if content == "\n"

            return false unless content.include?("\n")

            newlines = content.scan("\n")
            newlines.size > 1
          end

          # Check if whitespace content is non-newline whitespace
          # @rbs content: String
          def non_newline_whitespace?(content) #: bool
            !content.include?("\n")
          end

          # Check indentation of whitespace node
          # @rbs whitespace: Herb::AST::WhitespaceNode
          # @rbs index: Integer
          # @rbs total_whitespace_nodes: Integer
          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_indentation(whitespace, index, total_whitespace_nodes, node) #: void
            is_last_whitespace = index == total_whitespace_nodes - 1
            expected_indent = if is_last_whitespace
                                node.location.start.column
                              else
                                node.location.start.column + 2
                              end

            return if whitespace.location.end.column == expected_indent

            add_offense(message: EXTRA_SPACE_NO_SPACE, location: whitespace.location)
          end

          # @rbs node: Herb::AST::HTMLCloseTagNode
          def check_close_tag(node) #: void
            return unless node.tag_name

            # Report all whitespace nodes (matching TypeScript implementation)
            node.children.each do |child|
              next unless child.is_a?(Herb::AST::WhitespaceNode)

              add_offense(message: EXTRA_SPACE_NO_SPACE, location: child.location)
            end
          end
        end
      end
    end
  end
end
