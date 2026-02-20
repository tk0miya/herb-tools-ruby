# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-head-only-elements.ts
# Documentation: https://herb-tools.dev/linter/rules/html-head-only-elements

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Enforce that certain elements only appear inside the `<head>` section of the document.
        #
        #   Elements like `<title>`, `<meta>`, `<base>`, `<link>`, and `<style>` are permitted only inside the
        #   `<head>` element. They must not appear inside `<body>` or outside of `<html>`. Placing them elsewhere
        #   produces invalid HTML and relies on browser error correction.
        #
        # Good:
        #   <head>
        #     <title>My Page</title>
        #     <meta charset="UTF-8">
        #     <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #     <link rel="stylesheet" href="/styles.css">
        #   </head>
        #
        #   <body>
        #     <h1>Welcome</h1>
        #   </body>
        #
        #   <head>
        #     <%= csrf_meta_tags %>
        #     <%= csp_meta_tag %>
        #     <%= favicon_link_tag 'favicon.ico' %>
        #     <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
        #     <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
        #
        #     <title><%= content_for?(:title) ? yield(:title) : "Default Title" %></title>
        #   </head>
        #
        #   <body>
        #     <svg>
        #       <title>Chart Title</title>
        #       <rect width="100" height="100" />
        #     </svg>
        #   </body>
        #
        #   <body>
        #     <div itemscope itemtype="https://schema.org/Book">
        #       <span itemprop="name">The Hobbit</span>
        #       <meta itemprop="author" content="J.R.R. Tolkien">
        #       <meta itemprop="isbn" content="978-0618260300">
        #     </div>
        #   </body>
        #
        # Bad:
        #   <body>
        #     <title>My Page</title>
        #
        #     <meta charset="UTF-8">
        #
        #     <link rel="stylesheet" href="/styles.css">
        #
        #     <h1>Welcome</h1>
        #   </body>
        #
        #   <body>
        #     <title><%= content_for?(:title) ? yield(:title) : "Default Title" %></title>
        #   </body>
        #
        #   <body>
        #     <!-- Regular meta tags (name, charset, http-equiv) must be in <head> -->
        #     <meta name="description" content="Page description">
        #     <meta charset="UTF-8">
        #     <meta http-equiv="refresh" content="30">
        #   </body>
        #
        class HeadOnlyElements < VisitorRule
          HEAD_ONLY_ELEMENTS = %w[title meta link base style].freeze #: Array[String]

          def self.rule_name = "html-head-only-elements" #: String
          def self.description = "Disallow head-only elements outside of <head>" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @element_stack: Array[String]
          attr_reader :element_stack

          # @rbs override
          def on_new_investigation
            super
            @element_stack = []
          end

          # @rbs override
          def visit_html_element_node(node)
            tag = tag_name(node)

            check_head_only_element(node, tag)

            element_stack.push(tag)
            super
            element_stack.pop
          end

          private

          # @rbs node: untyped -- HTMLElementNode
          # @rbs tag: String
          def check_head_only_element(node, tag) #: void
            return if inside_head?
            return unless inside_body?
            return unless HEAD_ONLY_ELEMENTS.include?(tag)
            return if allowed_exception?(node, tag)

            add_offense(
              message: "Element `<#{tag}>` must be placed inside the `<head>` tag.",
              location: node.location
            )
          end

          # @rbs node: untyped -- HTMLElementNode
          # @rbs tag: String
          def allowed_exception?(node, tag) #: bool
            (tag == "title" && inside_svg?) ||
              (tag == "style" && inside_svg?) ||
              (tag == "meta" && itemprop_attribute?(node))
          end

          # @rbs node: untyped -- HTMLElementNode
          def itemprop_attribute?(node) #: bool
            attribute?(node, "itemprop")
          end

          def inside_head? #: bool
            element_stack.include?("head")
          end

          def inside_body? #: bool
            element_stack.include?("body")
          end

          def inside_svg? #: bool
            element_stack.include?("svg")
          end
        end
      end
    end
  end
end
