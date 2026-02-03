# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows duplicate <meta> elements with the same name attribute.
      #
      # Each meta name should only appear once in a document. Duplicate meta
      # elements with the same name can cause unpredictable behavior as search
      # engines and browsers may use different values.
      #
      # Good:
      #   <meta name="description" content="Page description">
      #   <meta name="viewport" content="width=device-width">
      #
      # Bad:
      #   <meta name="description" content="First">
      #   <meta name="description" content="Second">
      #
      # @see https://herb-tools.dev/linter/rules/html-no-duplicate-meta-names Documentation
      # @see https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-meta-names.ts Source
      class HtmlNoDuplicateMetaNames < VisitorRule
        def self.rule_name #: String
          "html-no-duplicate-meta-names"
        end

        def self.description #: String
          "Disallow duplicate meta elements with the same name attribute"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def check(document, context)
          @seen_meta_names = {} #: Hash[String, Herb::Location]
          super
        end

        # @rbs override
        def visit_html_element_node(node)
          check_duplicate_meta_name(node) if meta_element?(node)
          super
        end

        private

        # @rbs node: Herb::AST::HTMLElementNode
        def meta_element?(node) #: bool
          tag_name(node) == "meta"
        end

        # @rbs node: Herb::AST::HTMLElementNode
        def check_duplicate_meta_name(node) #: void
          name_attr = find_attribute(node, "name")
          name_value = attribute_value(name_attr)
          return if name_value.nil? || name_value.empty?

          normalized_name = name_value.downcase

          if @seen_meta_names.key?(normalized_name)
            first_line = @seen_meta_names[normalized_name].start.line
            add_offense(
              message: "Duplicate meta name '#{name_value}' (first defined at line #{first_line})",
              location: node.location
            )
          else
            @seen_meta_names[normalized_name] = node.location
          end
        end
      end
    end
  end
end
