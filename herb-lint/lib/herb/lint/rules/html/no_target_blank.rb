# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that warns about target="_blank" without rel="noopener" or rel="noreferrer".
        #
        # Links with target="_blank" can expose the opening page to security risks
        # via `window.opener`. Adding rel="noopener" or rel="noreferrer" mitigates this.
        #
        # Good:
        #   <a href="https://example.com" target="_blank" rel="noopener noreferrer">Link</a>
        #   <a href="https://example.com" target="_blank" rel="noopener">Link</a>
        #   <a href="https://example.com" target="_blank" rel="noreferrer">Link</a>
        #
        # Bad:
        #   <a href="https://example.com" target="_blank">Link</a>
        #   <a href="https://example.com" target="_blank" rel="stylesheet">Link</a>
        class NoTargetBlank < VisitorRule
          def self.rule_name #: String
            "html/no-target-blank"
          end

          def self.description #: String
            "Disallow target=\"_blank\" without rel=\"noopener\" or rel=\"noreferrer\""
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            if target_blank?(node) && !safe_rel?(node)
              add_offense(
                message: 'Links with target="_blank" should include rel="noopener" or rel="noreferrer"',
                location: node.location
              )
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def target_blank?(node) #: bool
            attribute_value(find_attribute(node, "target"))&.downcase == "_blank"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def safe_rel?(node) #: bool
            value = attribute_value(find_attribute(node, "rel"))
            return false if value.nil? || value.empty?

            rel_values = value.downcase.split
            rel_values.include?("noopener") || rel_values.include?("noreferrer")
          end
        end
      end
    end
  end
end
