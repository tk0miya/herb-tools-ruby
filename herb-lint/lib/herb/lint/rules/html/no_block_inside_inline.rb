# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-block-inside-inline.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-block-inside-inline

module Herb
  module Lint
    module Rules
      # Rule that disallows block-level elements nested inside inline elements.
      #
      # Block-level elements like `<div>`, `<p>`, `<blockquote>` must not be
      # placed inside inline elements like `<span>`, `<a>`, `<em>`. This
      # violates HTML nesting rules and causes unpredictable rendering.
      #
      # Good:
      #   <div><span>Inline in block</span></div>
      #
      # Bad:
      #   <span><div>Block in inline</div></span>
      #   <a href="/"><p>Paragraph in anchor</p></a>
      class HtmlNoBlockInsideInline < VisitorRule
        # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Inline_elements
        INLINE_ELEMENTS = Set.new(
          %w[
            a abbr acronym b bdi bdo big br cite code data dfn em i kbd label
            mark output q rb rp rt rtc ruby s samp small span strong sub sup
            time tt u var wbr
          ]
        ).freeze #: Set[String]

        # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Block-level_elements
        BLOCK_ELEMENTS = Set.new(
          %w[
            address article aside blockquote dd details dialog div dl dt
            fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 header
            hgroup hr li main nav ol p pre section summary table ul
          ]
        ).freeze #: Set[String]

        def self.rule_name #: String
          "html-no-block-inside-inline"
        end

        def self.description #: String
          "Disallow block-level elements nested inside inline elements"
        end

        def self.default_severity #: String
          "error"
        end

        # @rbs @inline_depth: Integer

        # @rbs override
        def on_new_investigation #: void
          super
          @inline_depth = 0
        end

        # @rbs override
        def visit_html_element_node(node)
          tag = tag_name(node)

          if inline_element?(tag)
            @inline_depth += 1
            super
            @inline_depth -= 1
          elsif block_element?(tag) && @inline_depth.positive?
            add_offense(
              message: "Block-level element `<#{raw_tag_name(node)}>` must not be nested inside an inline element",
              location: node.location
            )
            saved_depth = @inline_depth
            @inline_depth = 0
            super
            @inline_depth = saved_depth
          else
            super
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
