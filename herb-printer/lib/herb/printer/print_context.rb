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

      # Increment indent level
      def indent #: void
        @indent_level += 1
      end

      # Decrement indent level
      def dedent #: void
        @indent_level -= 1
      end

      # Push tag name onto the tag stack
      #
      # @rbs tag_name: String
      def enter_tag(tag_name) #: void
        @tag_stack.push(tag_name)
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
