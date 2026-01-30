# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Erb
        # Rule that enforces consistent spacing inside ERB tags.
        #
        # ERB tags should have exactly one space after the opening tag
        # and one space before the closing tag.
        #
        # Good:
        #   <%= @user.name %>
        #   <% if @show %>
        #
        # Bad:
        #   <%=@user.name%>
        #   <%   if @show   %>
        class ErbTagSpacing < VisitorRule
          def self.rule_name #: String
            "erb/erb-tag-spacing"
          end

          def self.description #: String
            "Consistent spacing inside ERB tags"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_child_nodes(node)
            check_spacing(node) if node.class.name.start_with?("Herb::AST::ERB")
            super
          end

          private

          # @rbs node: Herb::AST::Node
          def check_spacing(node) #: void
            value = node.content.value
            return if node.tag_closing.value.empty?

            check_leading_space(node, value)
            check_trailing_space(node, value)
          end

          # @rbs node: Herb::AST::Node
          # @rbs value: String
          def check_leading_space(node, value) #: void
            if value.empty? || !value.start_with?(" ")
              add_offense(
                message: "Expected single space after `#{node.tag_opening.value}` inside ERB tag",
                location: node.location
              )
            elsif value.start_with?("  ")
              add_offense(
                message: "Expected single space after `#{node.tag_opening.value}` inside ERB tag, " \
                         "but found multiple spaces",
                location: node.location
              )
            end
          end

          # @rbs node: Herb::AST::Node
          # @rbs value: String
          def check_trailing_space(node, value) #: void
            if value.empty? || !value.end_with?(" ")
              add_offense(
                message: "Expected single space before `#{node.tag_closing.value}` inside ERB tag",
                location: node.location
              )
            elsif value.end_with?("  ")
              add_offense(
                message: "Expected single space before `#{node.tag_closing.value}` inside ERB tag, " \
                         "but found multiple spaces",
                location: node.location
              )
            end
          end
        end
      end
    end
  end
end
