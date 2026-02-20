# frozen_string_literal: true

module Herb
  module Printer
    # Abstract base class for AST-to-source printers.
    #
    # Subclasses override `visit_*_node` methods to define how each node type
    # is serialized. A subclass with no overrides produces empty output.
    class Base < ::Herb::Visitor
      attr_reader :context #: PrintContext

      # Print the given input to a source string.
      #
      # @rbs input: Herb::ParseResult | Herb::AST::Node
      # @rbs ignore_errors: bool
      def self.print(input, ignore_errors: false) #: String
        node = input.is_a?(::Herb::ParseResult) ? input.value : input
        validate_no_errors!(node) unless ignore_errors

        printer = new
        printer.visit(node)
        printer.context.output
      end

      # Raise PrintError if node tree contains parse errors.
      #
      # @rbs node: Herb::AST::Node
      def self.validate_no_errors!(node) #: void
        errors = node.recursive_errors
        return if errors.empty?

        raise PrintError, "Cannot print AST with parse errors (#{errors.size} error(s) found)"
      end
      private_class_method :validate_no_errors!

      def initialize #: void
        super
        @context = PrintContext.new
      end

      private

      # Write text to the output context.
      #
      # @rbs text: String
      def write(text) #: void
        context.write(text)
      end
    end
  end
end
