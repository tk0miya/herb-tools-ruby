# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that discourages inline event handlers.
        #
        # Inline event handlers (onclick, onmouseover, etc.) mix behavior with
        # markup and are considered a bad practice. Use unobtrusive JavaScript
        # instead.
        #
        # Good:
        #   <button data-action="click">Click</button>
        #
        # Bad:
        #   <button onclick="handleClick()">Click</button>
        #   <div onmouseover="highlight()">Hover me</div>
        class NoInlineEventHandlers < VisitorRule
          INLINE_EVENT_HANDLER_PATTERN = /\Aon[a-z]/

          def self.rule_name #: String
            "html/no-inline-event-handlers"
          end

          def self.description #: String
            "Disallow inline event handlers"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            check_inline_event_handlers(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def check_inline_event_handlers(node) #: void
            return unless node.open_tag

            node.open_tag.children.each do |child|
              next unless child.is_a?(Herb::AST::HTMLAttributeNode)

              name = attribute_name(child)
              next if name.nil?

              next unless INLINE_EVENT_HANDLER_PATTERN.match?(name.downcase)

              add_offense(
                message: "Avoid inline event handler '#{name}'",
                location: child.location
              )
            end
          end
        end
      end
    end
  end
end
