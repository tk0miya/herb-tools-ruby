# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module A11y
        # Rule that disallows the use of accesskey attributes.
        #
        # The accesskey attribute creates keyboard shortcuts that can conflict
        # with screen reader and assistive technology shortcuts, causing
        # accessibility issues. The shortcuts are also inconsistent across
        # browsers and operating systems.
        #
        # Good:
        #   <button>Save</button>
        #
        # Bad:
        #   <button accesskey="s">Save</button>
        class NoAccessKey < VisitorRule
          def self.rule_name #: String
            "a11y/no-access-key"
          end

          def self.description #: String
            "Disallow use of accesskey attribute"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            if attribute?(node, "accesskey")
              add_offense(
                message: "Unexpected accesskey attribute. The accesskey attribute can cause " \
                         "accessibility issues due to conflicts with screen reader shortcuts",
                location: node.location
              )
            end
            super
          end
        end
      end
    end
  end
end
