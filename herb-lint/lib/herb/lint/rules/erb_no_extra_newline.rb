# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows extra blank lines inside ERB tags.
      #
      # ERB tags should not contain leading or trailing blank lines,
      # or multiple consecutive blank lines within the content.
      #
      # Good:
      #   <% value %>
      #   <% if condition
      #        do_something
      #      end %>
      #
      # Bad:
      #   <%
      #
      #     value
      #
      #   %>
      #   <% value
      #
      #
      #      another %>
      class ErbNoExtraNewline < VisitorRule
        def self.rule_name #: String
          "erb-no-extra-newline"
        end

        def self.description #: String
          "Disallow extra blank lines inside ERB tags"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_erb_content_node(node)
          return super if node.content.nil?

          content_value = node.content.value
          return super if content_value.nil? || content_value.empty?

          if extra_newlines?(content_value)
            add_offense(
              message: "Remove extra blank lines inside ERB tag",
              location: node.location
            )
          end
          super
        end

        private

        # @rbs content: String
        def extra_newlines?(content) #: bool
          # Check for leading blank lines (starts with newline followed by blank line)
          return true if content.match?(/\A\n\s*\n/)

          # Check for trailing blank lines (ends with blank line followed by newline)
          return true if content.match?(/\n\s*\n\s*\z/)

          # Check for multiple consecutive blank lines in the middle (3+ newlines with only whitespace between)
          return true if content.match?(/\n\s*\n\s*\n/)

          false
        end
      end
    end
  end
end
