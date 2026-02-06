# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-body-only-elements.ts
# Documentation: https://herb-tools.dev/linter/rules/html-body-only-elements

module Herb
  module Lint
    module Rules
      # Rule that ensures body-only elements are not placed inside `<head>`.
      #
      # Certain HTML elements (e.g., `<div>`, `<p>`, `<main>`) are only valid
      # inside `<body>`. Placing them inside `<head>` is invalid HTML.
      #
      # Good:
      #   <body>
      #     <div>Content in body</div>
      #   </body>
      #
      # Bad:
      #   <head>
      #     <div>Content in head</div>
      #   </head>
      class HtmlBodyOnlyElements < VisitorRule
        DOCUMENT_ONLY_TAGS = %w[html].freeze #: Array[String]
        HTML_ONLY_TAGS = %w[body head].freeze #: Array[String]
        HEAD_ONLY_TAGS = %w[base link meta style title].freeze #: Array[String]
        HEAD_AND_BODY_TAGS = %w[noscript script template].freeze #: Array[String]

        NON_BODY_TAGS = [
          *DOCUMENT_ONLY_TAGS, *HTML_ONLY_TAGS, *HEAD_ONLY_TAGS, *HEAD_AND_BODY_TAGS
        ].freeze #: Array[String]

        def self.rule_name #: String
          "html-body-only-elements"
        end

        def self.description #: String
          "Certain elements should only appear inside `<body>`"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs @element_stack: Array[String]

        # @rbs override
        def on_new_investigation #: void
          super
          @element_stack = []
        end

        # @rbs override
        def visit_html_element_node(node)
          tag = tag_name(node)
          return super unless tag

          if inside_head? && !inside_body? && body_only_tag?(tag)
            add_offense(
              message: "Element `<#{tag}>` must be placed inside the `<body>` tag.",
              location: node.location
            )
          end

          @element_stack.push(tag)
          super
          @element_stack.pop
        end

        private

        def inside_head? #: bool
          @element_stack.include?("head")
        end

        def inside_body? #: bool
          @element_stack.include?("body")
        end

        # @rbs tag_name: String
        def body_only_tag?(tag_name) #: bool
          !NON_BODY_TAGS.include?(tag_name)
        end
      end
    end
  end
end
