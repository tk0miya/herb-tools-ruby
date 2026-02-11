# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-attribute-must-be-valid.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-attribute-must-be-valid

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow unknown or invalid `aria-*` attributes. Only attributes defined in the WAI-ARIA specification
        #   should be used. This rule helps catch typos (e.g. `aria-lable`), misuse, or outdated attribute names that
        #   won't be interpreted by assistive technologies.
        #
        # Good:
        #   <div role="button" aria-pressed="false">Toggle</div>
        #   <input type="text" aria-label="Search" autocomplete="off">
        #   <span role="heading" aria-level="2">Title</span>
        #
        # Bad:
        #   <div role="button" aria-presed="false">Toggle</div>
        #
        #   <input type="text" aria-lable="Search" autocomplete="off">
        #
        #   <span aria-size="large" role="heading" aria-level="2">Title</span>
        #
        class AriaAttributeMustBeValid < VisitorRule
          # Valid ARIA attributes from the WAI-ARIA specification.
          VALID_ARIA_ATTRIBUTES = Set.new(
            %w[
              aria-activedescendant
              aria-atomic
              aria-autocomplete
              aria-busy
              aria-checked
              aria-colcount
              aria-colindex
              aria-colspan
              aria-controls
              aria-current
              aria-describedby
              aria-details
              aria-disabled
              aria-dropeffect
              aria-errormessage
              aria-expanded
              aria-flowto
              aria-grabbed
              aria-haspopup
              aria-hidden
              aria-invalid
              aria-keyshortcuts
              aria-label
              aria-labelledby
              aria-level
              aria-live
              aria-modal
              aria-multiline
              aria-multiselectable
              aria-orientation
              aria-owns
              aria-placeholder
              aria-posinset
              aria-pressed
              aria-readonly
              aria-relevant
              aria-required
              aria-roledescription
              aria-rowcount
              aria-rowindex
              aria-rowspan
              aria-selected
              aria-setsize
              aria-sort
              aria-valuemax
              aria-valuemin
              aria-valuenow
              aria-valuetext
            ]
          ).freeze #: Set[String]

          def self.rule_name = "html-aria-attribute-must-be-valid" #: String
          def self.description = "ARIA attributes must be valid" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            name = attribute_name(node)

            if name && aria_attribute?(name) && !valid_aria_attribute?(name)
              add_offense(
                message: "The attribute `#{name}` is not a valid ARIA attribute. " \
                         "ARIA attributes must match the WAI-ARIA specification.",
                location: node.location
              )
            end
            super
          end

          private

          # @rbs name: String
          def aria_attribute?(name) #: bool
            name.downcase.start_with?("aria-")
          end

          # @rbs name: String
          def valid_aria_attribute?(name) #: bool
            VALID_ARIA_ATTRIBUTES.include?(name.downcase)
          end
        end
      end
    end
  end
end
