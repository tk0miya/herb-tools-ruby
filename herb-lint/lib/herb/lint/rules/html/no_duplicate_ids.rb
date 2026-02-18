# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-ids.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-ids

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Ensure that `id` attribute is unique within a document.
        #
        # Good:
        #   <div id="header">Header</div>
        #   <div id="main-content">Main Content</div>
        #   <div id="footer">Footer</div>
        #
        #   <div id="<%= dom_id("header") %>">Header</div>
        #   <div id="<%= dom_id("main_content") %>">Main Content</div>
        #   <div id="<%= dom_id("footer") %>">Footer</div>
        #
        # Bad:
        #   <div id="header">Header</div>
        #
        #   <div id="header">Duplicate Header</div>
        #
        #   <div id="footer">Footer</div>
        #
        #   <div id="<%= dom_id("header") %>">Header</div>
        #
        #   <div id="<%= dom_id("header") %>">Duplicate Header</div>
        #
        #   <div id="<%= dom_id("footer") %>">Footer</div>
        #
        class NoDuplicateIds < VisitorRule
          def self.rule_name = "html-no-duplicate-ids" #: String
          def self.description = "Disallow duplicate id attribute values" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @seen_ids: Hash[String, Herb::Location]

          # @rbs override
          def on_new_investigation #: void
            super
            @seen_ids = {}
          end

          # @rbs override
          def visit_html_attribute_node(node)
            if id_attribute?(node)
              id_value = extract_id_value(node)
              check_duplicate_id(id_value, node) if id_value && !id_value.empty?
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLAttributeNode
          def id_attribute?(node) #: bool
            attribute_name(node)&.downcase == "id"
          end

          # Extract the full text value of an id attribute, including ERB expressions.
          # For static values like `id="header"`, returns "header".
          # For ERB values like `id="<%= dom_id("header") %>"`, returns the printed source text.
          #
          # @rbs node: Herb::AST::HTMLAttributeNode
          def extract_id_value(node) #: String?
            return nil if node.value.nil?

            children = node.value.children
            return nil if children.empty?

            if children.all? { _1.is_a?(Herb::AST::LiteralNode) }
              attribute_value(node)
            else
              children.map { Herb::Printer::IdentityPrinter.print(_1) }.join
            end
          end

          # @rbs id_value: String
          # @rbs node: Herb::AST::HTMLAttributeNode
          def check_duplicate_id(id_value, node) #: void
            if @seen_ids.key?(id_value)
              add_offense(
                message: "Duplicate id '#{id_value}' (first defined at line #{@seen_ids[id_value].start.line})",
                location: node.location
              )
            else
              @seen_ids[id_value] = node.location
            end
          end
        end
      end
    end
  end
end
