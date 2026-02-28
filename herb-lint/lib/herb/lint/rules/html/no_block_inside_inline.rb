# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-block-inside-inline.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-block-inside-inline

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Prevent block-level elements from being placed inside inline elements.
        #
        # Good:
        #   <span>
        #     Hello <strong>World</strong>
        #   </span>
        #
        #   <div>
        #     <p>Paragraph inside div (valid)</p>
        #   </div>
        #
        #   <a href="#">
        #     <img src="icon.png" alt="Icon">
        #     <span>Link text</span>
        #   </a>
        #
        # Bad:
        #   <span>
        #     <div>Invalid block inside span</div>
        #   </span>
        #
        #   <span>
        #     <p>Paragraph inside span (invalid)</p>
        #   </span>
        #
        #   <a href="#">
        #     <div class="card">
        #       <h2>Card title</h2>
        #       <p>Card content</p>
        #     </div>
        #   </a>
        #
        #   <strong>
        #     <section>Section inside strong</section>
        #   </strong>
        #
        class NoBlockInsideInline < VisitorRule
          # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Inline_elements
          INLINE_ELEMENTS = Set.new(
            %w[
              a abbr acronym b bdo big br button cite code dfn em i img input
              kbd label map object output q samp script select small span strong
              sub sup textarea time tt var
            ]
          ).freeze #: Set[String]

          # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Block-level_elements
          BLOCK_ELEMENTS = Set.new(
            %w[
              address article aside blockquote canvas dd div dl dt fieldset
              figcaption figure footer form h1 h2 h3 h4 h5 h6 header hr li main
              nav noscript ol p pre section table tfoot ul video
            ]
          ).freeze #: Set[String]

          def self.rule_name = "html-no-block-inside-inline" #: String
          def self.description = "Disallow block-level elements nested inside inline elements" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs @inline_stack: Array[String]

          # @rbs override
          def on_new_investigation
            super
            @inline_stack = []
          end

          # @rbs override
          def visit_html_element_node(node) # rubocop:disable Metrics/MethodLength
            tag = tag_name(node)
            return super unless tag

            is_inline = inline_element?(tag)
            is_block = block_element?(tag)
            is_unknown = !is_inline && !is_block

            # Report if block or unknown element is inside inline element
            if (is_block || is_unknown) && !@inline_stack.empty?
              parent_inline = @inline_stack.last
              element_type = is_block ? "Block-level" : "Unknown"
              add_offense(
                message:
                  "#{element_type} element `<#{raw_tag_name(node)}>` cannot be placed " \
                  "inside inline element `<#{parent_inline}>`.",
                location: node.location
              )
            end

            if is_inline
              # Visit inline element and track it on stack
              @inline_stack.push(tag)
              super
              @inline_stack.pop
            else
              # Visit block element: save and reset stack, then restore
              saved_stack = @inline_stack.dup
              @inline_stack = []
              super
              @inline_stack = saved_stack
            end
          end

          private

          # @rbs tag: String?
          def inline_element?(tag) #: bool
            return false unless tag

            INLINE_ELEMENTS.include?(tag)
          end

          # @rbs tag: String?
          def block_element?(tag) #: bool
            return false unless tag

            BLOCK_ELEMENTS.include?(tag)
          end
        end
      end
    end
  end
end
