# frozen_string_literal: true

module Herb
  module Format
    # Detects `<%# herb:formatter ignore %>` directives in a parsed AST.
    #
    # The TypeScript reference implementation (format-ignore.ts) handles formatter
    # directive detection within the formatter package itself. The Ruby implementation
    # follows this same pattern, keeping the ignore detection logic self-contained.
    module FormatIgnore
      FORMATTER_IGNORE_COMMENT = "herb:formatter ignore"

      # Check if the AST contains a herb:formatter ignore directive.
      # Traverses ERB comment nodes looking for an exact match.
      #
      # @rbs document: Herb::AST::DocumentNode
      def self.ignore?(document) #: bool
        detector = IgnoreDetector.new
        document.accept(detector)
        detector.ignore_directive_found
      end

      # Check if a single node is a herb:formatter ignore comment.
      # Returns true only for ERB comment nodes (<%# ... %>) whose content
      # exactly matches the ignore directive.
      #
      # @rbs node: Herb::AST::Node
      def self.ignore_comment?(node) #: bool
        return false unless node.is_a?(Herb::AST::ERBContentNode)
        return false unless node.tag_opening&.value == "<%#"

        content = node.content&.value
        return false unless content

        content.strip == FORMATTER_IGNORE_COMMENT
      end

      # Internal Visitor subclass that traverses the AST to detect
      # the ignore directive. Stops traversal entirely once found.
      # :nodoc:
      class IgnoreDetector < Herb::Visitor
        attr_reader :ignore_directive_found #: bool

        def initialize #: void
          super
          @ignore_directive_found = false
        end

        # @rbs node: Herb::AST::Node
        def visit_child_nodes(node) #: void
          return if ignore_directive_found

          super
        end

        # @rbs node: Herb::AST::ERBContentNode
        def visit_erb_content_node(node) #: void
          return if ignore_directive_found

          if FormatIgnore.ignore_comment?(node)
            @ignore_directive_found = true
            return
          end

          super
        end
      end
    end
  end
end
