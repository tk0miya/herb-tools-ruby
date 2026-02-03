# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that enforces consistent use of right-trim markers in ERB tags.
      #
      # ERB supports right-trim markers (`-%>`) that remove trailing whitespace
      # after the tag. This rule enforces consistency in their usage.
      #
      # Good (consistent - never using right-trim):
      #   <% if condition %>
      #     <p>Content</p>
      #   <% end %>
      #
      # Good (consistent - always using right-trim):
      #   <% if condition -%>
      #     <p>Content</p>
      #   <% end -%>
      #
      # Bad (inconsistent):
      #   <% if condition -%>
      #     <p>Content</p>
      #   <% end %>
      class ErbRightTrim < VisitorRule
        def self.rule_name #: String
          "erb-right-trim"
        end

        def self.description #: String
          "Enforce consistent use of right-trim marker"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs @erb_nodes: Array[untyped]

        # @rbs override
        def initialize(severity: nil, options: nil)
          super
          @erb_nodes = []
        end

        # Collect all ERB nodes (all ERB nodes have tag_closing)
        # @rbs override
        def visit_child_nodes(node)
          @erb_nodes << node if node.class.name.start_with?("Herb::AST::ERB")
          super
        end

        # Check consistency after visiting all nodes
        # @rbs override
        def visit_document_node(node)
          super
          check_consistency
        end

        private

        def check_consistency #: void
          # Count tags with and without right-trim
          with_trim = @erb_nodes.count { |node| right_trim?(node) }
          without_trim = @erb_nodes.count - with_trim

          # If both styles are used, report inconsistency
          return unless with_trim.positive? && without_trim.positive?

          # Report offenses for the minority style
          # When equal, prefer no trim (report tags with trim as inconsistent)
          if with_trim <= without_trim
            report_trim_offenses
          else
            report_no_trim_offenses
          end
        end

        # Report offenses for tags with right-trim marker
        def report_trim_offenses #: void
          @erb_nodes.each do |node|
            next unless right_trim?(node)

            add_offense(
              message: "Remove right-trim marker `-%>` for consistency",
              location: node.tag_closing.location
            )
          end
        end

        # Report offenses for tags without right-trim marker
        def report_no_trim_offenses #: void
          @erb_nodes.each do |node|
            next if right_trim?(node)

            add_offense(
              message: "Add right-trim marker `-%>` for consistency",
              location: node.tag_closing.location
            )
          end
        end

        # @rbs node: untyped
        def right_trim?(node) #: bool
          node.tag_closing&.value == "-%>"
        end
      end
    end
  end
end
