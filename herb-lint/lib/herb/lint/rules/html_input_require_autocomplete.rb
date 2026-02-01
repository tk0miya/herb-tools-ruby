# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that requires autocomplete attribute on input elements that accept text input.
      #
      # Input elements with text-accepting types should have an autocomplete
      # attribute to improve form accessibility and user experience.
      #
      # Good:
      #   <input type="text" name="email" autocomplete="email">
      #   <input type="checkbox" name="agree">
      #
      # Bad:
      #   <input type="text" name="email">
      class HtmlInputRequireAutocomplete < VisitorRule
        TYPES_REQUIRING_AUTOCOMPLETE = Set.new(
          %w[
            color
            date
            datetime-local
            email
            month
            number
            password
            range
            search
            tel
            text
            time
            url
            week
          ]
        ).freeze #: Set[String]

        def self.rule_name #: String
          "html-input-require-autocomplete"
        end

        def self.description #: String
          "Require autocomplete attribute on input elements that accept text input"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def visit_html_element_node(node)
          if input_element?(node) && !attribute?(node, "autocomplete")
            type_value = attribute_value(find_attribute(node, "type"))

            if type_value && TYPES_REQUIRING_AUTOCOMPLETE.include?(type_value.downcase)
              add_offense(
                message: "Add an `autocomplete` attribute to improve form accessibility. " \
                         'Use a specific value (e.g., `autocomplete="email"`), ' \
                         '`autocomplete="on"` for defaults, or `autocomplete="off"` to disable.',
                location: node.location
              )
            end
          end
          super
        end

        private

        # @rbs node: Herb::AST::HTMLElementNode
        def input_element?(node) #: bool
          node.tag_name&.value&.downcase == "input"
        end
      end
    end
  end
end
