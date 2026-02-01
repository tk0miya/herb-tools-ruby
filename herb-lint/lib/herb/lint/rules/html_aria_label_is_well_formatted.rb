# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that checks aria-label values are well-formatted.
      #
      # The `aria-label` attribute should have a meaningful value that is
      # not empty, not just whitespace, and starts with an uppercase letter.
      #
      # Good:
      #   <button aria-label="Submit form">Submit</button>
      #   <nav aria-label="Main navigation">...</nav>
      #
      # Bad:
      #   <button aria-label="">Submit</button>
      #   <button aria-label="   ">Submit</button>
      #   <button aria-label="submit form">Submit</button>
      class HtmlAriaLabelIsWellFormatted < VisitorRule
        def self.rule_name #: String
          "html-aria-label-is-well-formatted"
        end

        def self.description #: String
          "Require well-formatted aria-label values"
        end

        def self.default_severity #: String
          "warning"
        end

        # @rbs override
        def visit_html_element_node(node)
          attr = find_attribute(node, "aria-label")
          if attr
            value = attribute_value(attr)
            check_aria_label_value(attr, value)
          end
          super
        end

        private

        # @rbs attr: Herb::AST::HTMLAttributeNode
        # @rbs value: String?
        def check_aria_label_value(attr, value) #: void
          if value.nil? || value.strip.empty?
            add_offense(
              message: "Unexpected empty aria-label value",
              location: attr.location
            )
          elsif value != value.strip
            add_offense(
              message: "Unexpected leading or trailing whitespace in aria-label value",
              location: attr.location
            )
          elsif value.match?(/\A[a-z]/)
            add_offense(
              message: "aria-label value should start with an uppercase letter",
              location: attr.location
            )
          end
        end
      end
    end
  end
end
