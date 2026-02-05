# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that enforces ERB comment syntax.
      #
      # ERB comments should use the dedicated comment tag syntax (`<%#`)
      # rather than a statement tag with a Ruby line comment (`<% #`).
      #
      # Good:
      #   <%# This is a comment %>
      #
      # Bad:
      #   <% # This is a comment %>
      class ErbCommentSyntax < VisitorRule
        def self.rule_name #: String
          "erb-comment-syntax"
        end

        def self.description #: String
          "Enforce ERB comment style"
        end

        def self.default_severity #: String
          "warning"
        end

        def self.safe_autocorrectable? #: bool
          true
        end

        # @rbs override
        def visit_erb_content_node(node)
          if statement_tag?(node) && comment_content?(node)
            add_offense_with_autofix(
              message: "Use ERB comment tag `<%#` instead of `<% #`",
              location: node.tag_opening.location,
              node:
            )
          end
          super
        end

        # @rbs override
        def autofix(node, parse_result)
          parent = find_parent(parse_result, node)
          return false unless parent

          parent_array = parent_array_for(parent, node)
          return false unless parent_array

          new_node = build_comment_node(node)
          replace_node_in_array(parent_array, node, new_node)
        end

        private

        # @rbs node: Herb::AST::ERBContentNode
        def build_comment_node(node) #: Herb::AST::ERBContentNode
          new_tag_opening = Herb::Token.new(
            "<%#",
            node.tag_opening.range,
            node.tag_opening.location,
            node.tag_opening.type
          )

          new_content = build_comment_content(node)

          Herb::AST::ERBContentNode.new(
            node.type,
            node.location,
            node.errors,
            new_tag_opening,
            new_content,
            node.tag_closing,
            node.parsed,
            node.valid,
            node.analyzed_ruby
          )
        end

        # @rbs node: Herb::AST::ERBContentNode
        def build_comment_content(node) #: Herb::Token
          # Remove leading whitespace and # from content
          # Keep everything after the # including any leading space
          content = node.content.value
          new_content_value = content.sub(/\A\s*#/, "")

          Herb::Token.new(
            new_content_value,
            node.content.range,
            node.content.location,
            node.content.type
          )
        end

        # @rbs parent_array: Array[Herb::AST::Node]
        # @rbs old_node: Herb::AST::Node
        # @rbs new_node: Herb::AST::Node
        # rubocop:disable Naming/PredicateMethod
        def replace_node_in_array(parent_array, old_node, new_node) #: bool
          idx = parent_array.index(old_node)
          return false unless idx

          parent_array[idx] = new_node
          true
        end
        # rubocop:enable Naming/PredicateMethod

        # @rbs node: Herb::AST::ERBContentNode
        def statement_tag?(node) #: bool
          node.tag_opening.value == "<%"
        end

        # @rbs node: Herb::AST::ERBContentNode
        def comment_content?(node) #: bool
          node.content.value.match?(/\A\s*#/)
        end
      end
    end
  end
end
