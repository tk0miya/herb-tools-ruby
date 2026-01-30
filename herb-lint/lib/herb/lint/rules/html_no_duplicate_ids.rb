# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows duplicate id attribute values.
      #
      # The id attribute must be unique within a document. Duplicate ids
      # cause accessibility issues and break JavaScript functionality
      # that relies on getElementById.
      #
      # Good:
      #   <div id="header">...</div>
      #   <div id="footer">...</div>
      #
      # Bad:
      #   <div id="content">...</div>
      #   <div id="content">...</div>
      class HtmlNoDuplicateIds < VisitorRule
        def self.rule_name #: String
          "html-no-duplicate-ids"
        end

        def self.description #: String
          "Disallow duplicate id attribute values"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def check(document, context)
          @seen_ids = {} #: Hash[String, Herb::Location]
          super
        end

        # @rbs override
        def visit_html_attribute_node(node)
          if id_attribute?(node)
            id_value = attribute_value(node)
            check_duplicate_id(id_value, node) if id_value && !id_value.empty?
          end
          super
        end

        private

        # @rbs node: Herb::AST::HTMLAttributeNode
        def id_attribute?(node) #: bool
          attribute_name(node)&.downcase == "id"
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
