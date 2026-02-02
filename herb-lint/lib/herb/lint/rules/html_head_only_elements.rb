# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Rule that disallows head-only elements outside of `<head>`.
      #
      # Certain elements (`<title>`, `<meta>`, `<link>`, `<base>`) are only
      # valid inside the `<head>` section of an HTML document. Placing them
      # elsewhere (e.g., inside `<body>`) is invalid HTML.
      #
      # Good:
      #   <head>
      #     <title>Page Title</title>
      #     <meta charset="utf-8">
      #   </head>
      #
      # Bad:
      #   <body>
      #     <title>Page Title</title>
      #   </body>
      class HtmlHeadOnlyElements < VisitorRule
        HEAD_ONLY_ELEMENTS = %w[title meta link base].freeze #: Array[String]

        def self.rule_name #: String
          "html-head-only-elements"
        end

        def self.description #: String
          "Disallow head-only elements outside of <head>"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs override
        def check(document, context)
          @inside_head = false #: bool
          super
        end

        # @rbs override
        def visit_html_element_node(node)
          tag = node.tag_name&.value&.downcase

          if tag == "head"
            @inside_head = true
            super
            @inside_head = false
          else
            if !@inside_head && HEAD_ONLY_ELEMENTS.include?(tag)
              add_offense(
                message: "`<#{tag}>` element should only appear inside `<head>`",
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
