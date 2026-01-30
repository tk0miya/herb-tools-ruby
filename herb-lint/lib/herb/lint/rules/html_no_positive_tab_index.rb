# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows positive tabindex values.
        #
        # Using a positive tabindex value is an accessibility anti-pattern.
        # It disrupts the natural tab order of the page, making navigation
        # confusing for keyboard and assistive technology users.
        #
        # Good:
        #   <button tabindex="0">Click</button>
        #   <button tabindex="-1">Click</button>
        #
        # Bad:
        #   <button tabindex="1">Click</button>
        #   <div tabindex="5">Content</div>
        class NoPositiveTabIndex < VisitorRule
          def self.rule_name #: String
            "html-no-positive-tab-index"
          end

          def self.description #: String
            "Disallow positive tabindex values"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_attribute_node(node)
            if tabindex_attribute?(node)
              value = attribute_value(node)
              if positive_tabindex?(value)
                add_offense(
                  message: "Avoid positive tabindex value '#{value}' (disrupts natural tab order)",
                  location: node.location
                )
              end
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def tabindex_attribute?(node) #: bool
            attribute_name(node)&.downcase == "tabindex"
          end

          # @rbs value: String?
          def positive_tabindex?(value) #: bool
            return false if value.nil? || value.empty?

            integer_value = Integer(value, exception: false)
            return false if integer_value.nil?

            integer_value.positive?
          end
        end
      end
    end
  end
end
