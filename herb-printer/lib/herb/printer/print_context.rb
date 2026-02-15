# frozen_string_literal: true

module Herb
  module Printer
    # Output accumulator with indent/column tracking for printers.
    class PrintContext
      attr_reader :current_column #: Integer

      # @rbs @output: String
      # @rbs @indent_level: Integer
      # @rbs @tag_stack: Array[String]

      def initialize #: void
        @output = +""
        @indent_level = 0
        @current_column = 0
        @tag_stack = [] #: Array[String]
      end

      # Append text to the output buffer
      #
      # @rbs text: String
      def write(text) #: void
        @output << text
      end

      # Append text and track column position across newlines
      #
      # @rbs text: String
      def write_with_column_tracking(text) #: void
        @output << text

        last_newline = text.rindex("\n")
        if last_newline
          @current_column = text.length - last_newline - 1
        else
          @current_column += text.length
        end
      end

      # Increment indent level. If a block is given, automatically
      # calls dedent after the block completes (even if an exception occurs).
      #
      # @rbs &block: () -> void
      def indent(&block) #: void
        @indent_level += 1
        return unless block

        begin
          yield
        ensure
          dedent
        end
      end

      # Decrement indent level
      def dedent #: void
        @indent_level -= 1
      end

      # Push tag name onto the tag stack. If a block is given, automatically
      # calls exit_tag after the block completes (even if an exception occurs).
      #
      # @rbs tag_name: String
      # @rbs &block: () -> void
      def enter_tag(tag_name, &block) #: void
        @tag_stack.push(tag_name)
        return unless block

        begin
          yield
        ensure
          exit_tag
        end
      end

      # Pop tag name from the tag stack
      def exit_tag #: void
        @tag_stack.pop
      end

      # Whether the cursor is at column 0
      def at_start_of_line? #: bool
        @current_column.zero?
      end

      # Current indent depth
      def current_indent_level #: Integer
        @indent_level
      end

      # Copy of the current tag stack
      def tag_stack #: Array[String]
        @tag_stack.dup
      end

      # Return accumulated output string
      def output #: String
        @output.dup
      end

      # Clear all state (output, indent, column, tag stack)
      def reset #: void
        @output = +""
        @indent_level = 0
        @current_column = 0
        @tag_stack.clear
      end
    end
  end
end
