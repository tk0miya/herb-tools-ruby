# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-empty-attributes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-empty-attributes

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when certain restricted attributes are present but have an empty string as their value.
        #   These attributes are required to have meaningful values to function properly, and leaving
        #   them empty is typically either a mistake or unnecessary.
        #
        #   In most cases, if the value is not available, it's better to omit the attribute entirely.
        #
        # Good:
        #   <div id="header"></div>
        #   <img src="/logo.png" alt="Company logo">
        #   <input type="text" name="email" autocomplete="off">
        #
        #   <!-- Dynamic attributes with meaningful values -->
        #   <div data-<%= key %>="<%= value %>" aria-<%= prop %>="<%= description %>">
        #     Dynamic content
        #   </div>
        #
        #   <!-- if no class should be set, omit it completely -->
        #   <div>Plain div</div>
        #
        # Bad:
        #   <div id=""></div>
        #   <img src="" alt="Company logo">
        #   <input name="" autocomplete="off">
        #
        #   <div data-config="">Content</div>
        #   <button aria-label="">×</button>
        #
        #   <div class="">Plain div</div>
        #
        #   <!-- Dynamic attribute names with empty static values -->
        #   <div data-<%= key %>="" aria-<%= prop %>="   ">
        #     Problematic dynamic attributes
        #   </div>
        #
        class NoEmptyAttributes < VisitorRule
          # Attributes where an empty value is semantically valid.
          RESTRICTED_ATTRIBUTES = Set.new(%w[id class name for src href title data role]).freeze #: Set[String]

          OUTPUT_TAG_OPENINGS = Set.new(["<%=", "<%=="]).freeze #: Set[String]

          def self.rule_name = "html-no-empty-attributes" #: String
          def self.description = "Disallow empty attribute values" #: String
          def self.default_severity = "warning" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs override
          def visit_html_attribute_node(node)
            check_empty_attribute(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def check_empty_attribute(node) #: void
            name = attribute_name(node)
            return if name.nil?

            name_lower = name.downcase
            return unless restricted_attribute?(name_lower)
            return unless empty_value?(node)

            if data_attribute?(name_lower)
              add_offense(
                message: "Data attribute `#{name}` should not have an empty value. " \
                         "Either provide a meaningful value or use `#{name}` instead of `#{Herb::Printer::IdentityPrinter.print(node)}`.",
                location: node.location
              )
            else
              add_offense(
                message: "Attribute `#{name}` must not be empty. " \
                         "Either provide a meaningful value or remove the attribute entirely.",
                location: node.location
              )
            end
          end

          # @rbs name: String
          def restricted_attribute?(name) #: bool
            RESTRICTED_ATTRIBUTES.include?(name) ||
              data_attribute?(name) ||
              name.start_with?("aria-")
          end

          # @rbs name: String
          def data_attribute?(name) #: bool
            name.start_with?("data-")
          end

          # Check if an attribute has an explicit but empty (or whitespace-only) value
          # and the value does not contain ERB output content.
          # Boolean attributes (no value) return false.
          #
          # @rbs node: Herb::AST::HTMLAttributeNode
          def empty_value?(node) #: bool
            value = node.value
            # Boolean attributes (no value at all) are not "empty"
            return false if value.nil?
            # Skip if value contains ERB output content
            return false if contains_output_content?(value)

            value.children.all? do |child|
              case child
              when Herb::AST::LiteralNode
                child.content.nil? || child.content.strip.empty?
              else
                true
              end
            end
          end

          # Check if a node tree contains any ERB output content or non-whitespace literal text.
          #
          # @rbs node: Herb::AST::HTMLAttributeValueNode
          def contains_output_content?(node) #: bool
            node.children.any? do |child|
              case child
              when Herb::AST::ERBContentNode
                OUTPUT_TAG_OPENINGS.include?(child.tag_opening.value)
              when Herb::AST::LiteralNode
                child.content && !child.content.strip.empty?
              else
                false
              end
            end
          end
        end
      end
    end
  end
end
