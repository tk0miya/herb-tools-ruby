# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that disallows trailing whitespace after ERB tags.
        #
        # Detects spaces and tabs between the closing `%>` of an ERB tag
        # and the end of the line. Such whitespace is unnecessary and
        # produces extra whitespace in the rendered output.
        #
        # Good:
        #   <%= @user.name %>
        #   <% if @show %>
        #
        # Bad:
        #   <%= @user.name %>··
        #   <% if @show %>··
        class NoTrailingWhitespace < VisitorRule
          TRAILING_WHITESPACE_ONLY = /\A[ \t]+\z/

          def self.rule_name #: String
            "erb/erb-no-trailing-whitespace"
          end

          def self.description #: String
            "No trailing whitespace in ERB output"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def check(document, context)
            @source_lines = context.source.lines
            super
          end

          # Visit all ERB node types and check for trailing whitespace
          # after their closing tag on the same line.

          ERB_VISITOR_METHODS = %i[
            visit_erb_begin_node
            visit_erb_block_node
            visit_erb_case_match_node
            visit_erb_case_node
            visit_erb_content_node
            visit_erb_else_node
            visit_erb_end_node
            visit_erb_ensure_node
            visit_erb_for_node
            visit_erb_if_node
            visit_erb_in_node
            visit_erb_rescue_node
            visit_erb_unless_node
            visit_erb_until_node
            visit_erb_when_node
            visit_erb_while_node
            visit_erb_yield_node
          ].freeze

          ERB_VISITOR_METHODS.each do |method_name|
            define_method(method_name) do |node|
              check_trailing_whitespace_after_tag(node)
              super(node)
            end
          end

          private

          # @rbs @source_lines: Array[String]

          # @rbs node: untyped -- an ERB AST node with tag_closing
          def check_trailing_whitespace_after_tag(node) #: void
            tag_end = node.tag_closing.location.end
            trailing = trailing_whitespace_on_line(tag_end)
            return unless trailing

            add_offense(
              message: "Trailing whitespace detected",
              location: trailing
            )
          end

          # Returns the content after the given column on the line, with
          # the trailing newline stripped. Returns nil if nothing remains.
          #
          # @rbs line_index: Integer -- 0-based line index
          # @rbs column: Integer -- 0-based column offset
          def content_after(line_index, column) #: String?
            line = @source_lines[line_index]
            return nil unless line

            after = line[column..]
            return nil if after.nil? || after.empty?

            content = after.chomp
            content.empty? ? nil : content
          end

          # Builds a Location from a line number and column range.
          #
          # @rbs line: Integer -- 1-based line number
          # @rbs start_column: Integer -- 0-based start column
          # @rbs end_column: Integer -- 0-based end column (exclusive)
          def build_range(line, start_column, end_column) #: Herb::Location
            Herb::Location.new(
              Herb::Position.new(line, start_column),
              Herb::Position.new(line, end_column)
            )
          end

          # Returns a Location spanning the trailing whitespace after the given
          # position on the same line, or nil if none is found.
          #
          # @rbs position: untyped -- a position with line and column
          def trailing_whitespace_on_line(position) #: Herb::Location?
            content = content_after(position.line - 1, position.column)
            return nil unless content
            return nil unless content.match?(TRAILING_WHITESPACE_ONLY)

            build_range(position.line, position.column, position.column + content.length)
          end
        end
      end
    end
  end
end
