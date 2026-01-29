# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that enforces lowercase attribute names.
        #
        # HTML attribute names are case-insensitive, but lowercase is the
        # conventional style. Using lowercase improves consistency and
        # readability.
        #
        # Good:
        #   <div class="container">
        #   <input type="text">
        #
        # Bad:
        #   <div CLASS="container">
        #   <input TYPE="text">
        class LowercaseAttributes < VisitorRule
          def self.rule_name #: String
            "html/lowercase-attributes"
          end

          def self.description #: String
            "Attribute names should be lowercase"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_attribute_node(node)
            name = attribute_name(node)
            if name && name != name.downcase
              add_offense(
                message: "Attribute name '#{name}' should be lowercase",
                location: node.name.location
              )
            end
            super
          end
        end
      end
    end
  end
end
