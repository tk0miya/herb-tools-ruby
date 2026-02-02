# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows extra whitespace inside HTML tags,
      # including spaces between the tag name and attributes,
      # between consecutive attributes, trailing spaces before `>`,
      # incorrect spacing around `/>`, and multiline indentation.
      class HtmlNoSpaceInTag < VisitorRule
        EXTRA_SPACE_NO_SPACE = "Extra space detected where there should be no space."
        EXTRA_SPACE_SINGLE_SPACE = "Extra space detected where there should be a single space."
        EXTRA_SPACE_SINGLE_BREAK = "Extra space detected where there should be a single space or a single line break."
        NO_SPACE_SINGLE_SPACE = "No space detected where there should be a single space."

        def self.rule_name = "html-no-space-in-tag" #: String
        def self.description = "Disallow extra whitespace inside HTML tags" #: String
        def self.default_severity = "warning" #: String

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

        # --- Single-line open tag ---

        # @rbs node: Herb::AST::HTMLOpenTagNode
        def check_single_line_open_tag(node) #: void
          ws_nodes = node.children.select { |c| c.is_a?(Herb::AST::WhitespaceNode) }
          has_trailing = node.children.last.is_a?(Herb::AST::WhitespaceNode)
          trailing = has_trailing ? ws_nodes.last : nil
          inter_elements = has_trailing ? ws_nodes[...-1] : ws_nodes

          inter_elements.each do |ws|
            report(EXTRA_SPACE_SINGLE_SPACE, ws.location) if ws.value.value.length > 1
          end

          check_single_line_trailing(node, trailing)
        end

        # @rbs node: Herb::AST::HTMLOpenTagNode
        # @rbs trailing: Herb::AST::WhitespaceNode?
        def check_single_line_trailing(node, trailing) #: void
          if self_closing?(node)
            if trailing.nil?
              report(NO_SPACE_SINGLE_SPACE, node.tag_closing.location)
            elsif trailing.value.value.length > 1
              report(EXTRA_SPACE_NO_SPACE, trailing.location)
            end
          elsif trailing
            report(EXTRA_SPACE_NO_SPACE, trailing.location)
          end
        end

        # --- Close tag ---

        # @rbs node: Herb::AST::HTMLCloseTagNode
        def check_close_tag(node) #: void
          return unless node.tag_name

          node.children.each do |child|
            next unless child.is_a?(Herb::AST::WhitespaceNode)

            report(EXTRA_SPACE_NO_SPACE, child.location)
          end
        end

        # --- Multiline open tag ---

        # @rbs node: Herb::AST::HTMLOpenTagNode
        def check_multiline_open_tag(node) #: void
          attrs = node.children.select { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
          tag_col = node.location.start.column

          check_blank_lines(node)
          check_multiline_indentation(attrs, node.tag_closing, tag_col)
          check_multiline_trailing(node, attrs)
        end

        # @rbs node: Herb::AST::HTMLOpenTagNode
        def check_blank_lines(node) #: void
          node.children.chunk { |c| c.is_a?(Herb::AST::WhitespaceNode) }.each do |is_ws, group|
            next unless is_ws

            newline_count = group.count { |ws| ws.value.value.include?("\n") }
            next unless newline_count > 1

            location = Herb::Location.new(group.first.location.start, group.last.location.end)
            report(EXTRA_SPACE_SINGLE_BREAK, location)
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
        # @rbs attrs: Array[Herb::AST::HTMLAttributeNode]
        def check_multiline_trailing(node, attrs) #: void
          last = attrs.last || node.tag_name
          return unless node.tag_closing.location.start.line == last.location.end.line

          last_child = node.children.last
          return unless last_child.is_a?(Herb::AST::WhitespaceNode)
          return if last_child.value.value.include?("\n")

          report(EXTRA_SPACE_NO_SPACE, last_child.location)
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
