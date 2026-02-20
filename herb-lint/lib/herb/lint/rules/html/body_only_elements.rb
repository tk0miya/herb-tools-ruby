# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-body-only-elements.ts
# Documentation: https://herb-tools.dev/linter/rules/html-body-only-elements

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Enforce that specific HTML elements are only placed within the `<body>` tag.
        #
        # Good:
        #   <html>
        #     <head>
        #       <title>Page Title</title>
        #       <meta charset="utf-8">
        #     </head>
        #
        #     <body>
        #       <header>
        #         <h1>Welcome</h1>
        #         <nav>
        #           <ul>
        #             <li>Home</li>
        #           </ul>
        #         </nav>
        #       </header>
        #
        #       <main>
        #         <article>
        #           <section>
        #             <p>This is valid content.</p>
        #             <table>
        #               <tr><td>Data</td></tr>
        #             </table>
        #           </section>
        #         </article>
        #         <aside>
        #           <form>
        #             <input type="text" autocomplete="on">
        #           </form>
        #         </aside>
        #       </main>
        #
        #       <footer>
        #         <h2>Footer</h2>
        #       </footer>
        #     </body>
        #   </html>
        #
        # Bad:
        #   <html>
        #     <head>
        #       <title>Page Title</title>
        #       <h1>Welcome</h1>
        #
        #       <p>This should not be here.</p>
        #
        #     </head>
        #
        #     <body>
        #       <main>Valid content</main>
        #     </body>
        #   </html>
        #
        #   <html>
        #     <head>
        #       <nav>Navigation</nav>
        #
        #       <form>Form</form>
        #
        #     </head>
        #
        #     <body>
        #     </body>
        #   </html>
        #
        class BodyOnlyElements < VisitorRule
          DOCUMENT_ONLY_TAGS = %w[html].freeze #: Array[String]
          HTML_ONLY_TAGS = %w[body head].freeze #: Array[String]
          HEAD_ONLY_TAGS = %w[base link meta style title].freeze #: Array[String]
          HEAD_AND_BODY_TAGS = %w[noscript script template].freeze #: Array[String]

          NON_BODY_TAGS = [
            *DOCUMENT_ONLY_TAGS, *HTML_ONLY_TAGS, *HEAD_ONLY_TAGS, *HEAD_AND_BODY_TAGS
          ].freeze #: Array[String]

          def self.rule_name = "html-body-only-elements" #: String
          def self.description = "Certain elements should only appear inside `<body>`" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @element_stack: Array[String]

          # @rbs override
          def on_new_investigation
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
end
