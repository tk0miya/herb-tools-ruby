# frozen_string_literal: true

module Herb
  module Printer
    # Lossless round-trip printer that reconstructs the original source code
    # exactly from an AST produced by Herb.parse.
    class IdentityPrinter < Base
      # @rbs override
      def visit_literal_node(node)
        write(node.content)
      end

      # @rbs override
      def visit_html_text_node(node)
        write(node.content)
      end

      # @rbs override
      def visit_whitespace_node(node)
        write(node.value.value) if node.value
      end
    end
  end
end
