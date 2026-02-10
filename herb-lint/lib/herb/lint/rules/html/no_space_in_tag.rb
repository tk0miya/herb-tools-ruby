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
        class NoSpaceInTag < VisitorRule # rubocop:disable Metrics/ClassLength
          EXTRA_SPACE_NO_SPACE = "Extra space detected where there should be no space."
          EXTRA_SPACE_SINGLE_SPACE = "Extra space detected where there should be a single space."
          EXTRA_SPACE_SINGLE_BREAK = "Extra space detected where there should be a single space or a single line break."
          NO_SPACE_SINGLE_SPACE = "No space detected where there should be a single space."

          def self.rule_name = "html-no-space-in-tag" #: String
          def self.description = "Disallow extra whitespace inside HTML tags" #: String
          def self.default_severity = "warning" #: String

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

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

          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_single_line_open_tag(node) #: void
            children = node.children.select { _1.is_a?(Herb::AST::HTMLAttributeNode) }

            check_inter_element_gaps(node, children)
            check_trailing_gap(node, children.last || node.tag_name)
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs children: Array[Herb::AST::HTMLAttributeNode]
          def check_inter_element_gaps(node, children) #: void
            return if children.empty?

            gap = gap_size(node.tag_name, children.first)
            report(EXTRA_SPACE_SINGLE_SPACE, gap_loc(node.tag_name, children.first)) if gap > 1

            children.each_cons(2) do |left, right|
              gap = gap_size(left, right)
              report(EXTRA_SPACE_SINGLE_SPACE, gap_loc(left, right)) if gap > 1
            end
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs last: Herb::Token | Herb::AST::HTMLAttributeNode
          def check_trailing_gap(node, last) #: void
            gap = gap_size(last, node.tag_closing)

            if self_closing?(node)
              if gap.zero?
                report(NO_SPACE_SINGLE_SPACE, node.tag_closing.location)
              elsif gap > 1
                report(EXTRA_SPACE_NO_SPACE, gap_loc(last, node.tag_closing))
              end
            elsif gap.positive?
              report(EXTRA_SPACE_NO_SPACE, gap_loc(last, node.tag_closing))
            end
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_multiline_open_tag(node) #: void
            children = node.children.select { _1.is_a?(Herb::AST::HTMLAttributeNode) }
            tag_col = node.location.start.column

            check_blank_lines(node, children)
            check_multiline_indentation(children, node.tag_closing, tag_col)
            check_multiline_trailing(node, children)
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs children: Array[Herb::AST::HTMLAttributeNode]
          def check_blank_lines(node, children) #: void
            elements = [node.tag_name, *children, node.tag_closing]

            elements.each_cons(2) do |left, right|
              next unless right.location.start.line - left.location.end.line > 1

              report(EXTRA_SPACE_SINGLE_BREAK, gap_loc(left, right))
            end
          end

          # @rbs children: Array[Herb::AST::HTMLAttributeNode]
          # @rbs tag_closing: Herb::Token
          # @rbs tag_col: Integer
          def check_multiline_indentation(children, tag_closing, tag_col) #: void
            children.each do |child|
              report(EXTRA_SPACE_NO_SPACE, child.location) unless child.location.start.column == tag_col + 2
            end
            check_closing_indent(children.last, tag_closing, tag_col)
          end

          # @rbs last_child: Herb::AST::HTMLAttributeNode?
          # @rbs tag_closing: Herb::Token
          # @rbs tag_col: Integer
          def check_closing_indent(last_child, tag_closing, tag_col) #: void
            return if last_child && tag_closing.location.start.line == last_child.location.end.line
            return if tag_closing.location.start.column == tag_col

            report(EXTRA_SPACE_NO_SPACE, tag_closing.location)
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          # @rbs children: Array[Herb::AST::HTMLAttributeNode]
          def check_multiline_trailing(node, children) #: void
            last = children.last || node.tag_name

            return unless node.tag_closing.location.start.line == last.location.end.line

            gap = gap_size(last, node.tag_closing)
            return unless gap.positive?

            report(EXTRA_SPACE_NO_SPACE, gap_loc(last, node.tag_closing))
          end

          # @rbs node: Herb::AST::HTMLCloseTagNode
          def check_close_tag(node) #: void
            return unless node.tag_name

            before = gap_size(node.tag_opening, node.tag_name)
            after = gap_size(node.tag_name, node.tag_closing)

            report(EXTRA_SPACE_NO_SPACE, gap_loc(node.tag_opening, node.tag_name)) if before.positive?
            report(EXTRA_SPACE_NO_SPACE, gap_loc(node.tag_name, node.tag_closing)) if after.positive?
          end

          # @rbs left: Herb::Token | Herb::AST::HTMLAttributeNode
          # @rbs right: Herb::Token | Herb::AST::HTMLAttributeNode
          def gap_size(left, right) #: Integer
            right.location.start.column - left.location.end.column
          end

          # @rbs left: Herb::Token | Herb::AST::HTMLAttributeNode
          # @rbs right: Herb::Token | Herb::AST::HTMLAttributeNode
          def gap_loc(left, right) #: Herb::Location
            Herb::Location.new(
              Herb::Position.new(left.location.end.line, left.location.end.column),
              Herb::Position.new(right.location.start.line, right.location.start.column)
            )
          end

          # @rbs message: String
          # @rbs location: Herb::Location
          def report(message, location) #: void
            add_offense(message:, location:)
          end
        end
      end
    end
  end
end
