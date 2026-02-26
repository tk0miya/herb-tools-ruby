# frozen_string_literal: true

module Herb
  module Rewriter
    module BuiltIns
      # Sort Tailwind CSS classes according to recommended order.
      #
      # This rewriter traverses HTML class attributes and sorts Tailwind CSS
      # class names by their functional category (layout, spacing, typography,
      # etc.). The sort order approximates the order used by prettier-plugin-tailwindcss.
      #
      # Note: Herb AST nodes are immutable. This rewriter defines sorting
      # logic via tailwind_sort_key, which will be connected to AST
      # transformation once mutable AST support is available.
      class TailwindClassSorter < ASTRewriter
        # Tailwind CSS class prefix-to-category mapping.
        # Lower numbers sort earlier in the recommended order.
        CLASS_GROUPS = {
          # Layout
          "aspect" => 0, "block" => 0, "box" => 0, "break" => 0,
          "clear" => 0, "collapse" => 0, "columns" => 0, "container" => 0,
          "contents" => 0, "flex" => 0, "float" => 0, "flow" => 0,
          "grid" => 0, "hidden" => 0, "inline" => 0, "invisible" => 0,
          "isolation" => 0, "list" => 0, "object" => 0, "overflow" => 0,
          "overscroll" => 0, "table" => 0, "truncate" => 0, "visible" => 0,
          # Position
          "absolute" => 1, "bottom" => 1, "fixed" => 1, "inset" => 1,
          "left" => 1, "relative" => 1, "right" => 1, "static" => 1,
          "sticky" => 1, "top" => 1, "z" => 1,
          # Sizing
          "h" => 2, "max" => 2, "min" => 2, "size" => 2, "w" => 2,
          # Flexbox and Grid
          "auto" => 3, "basis" => 3, "col" => 3, "content" => 3,
          "gap" => 3, "grow" => 3, "items" => 3, "justify" => 3,
          "order" => 3, "place" => 3, "row" => 3, "self" => 3,
          "shrink" => 3,
          # Spacing
          "m" => 4, "mb" => 4, "me" => 4, "ml" => 4, "mr" => 4,
          "ms" => 4, "mt" => 4, "mx" => 4, "my" => 4,
          "p" => 4, "pb" => 4, "pe" => 4, "pl" => 4, "pr" => 4,
          "ps" => 4, "pt" => 4, "px" => 4, "py" => 4, "space" => 4,
          # Typography
          "accent" => 5, "align" => 5, "antialiased" => 5, "capitalize" => 5,
          "caret" => 5, "decoration" => 5, "font" => 5, "hyphens" => 5,
          "indent" => 5, "italic" => 5, "leading" => 5, "lowercase" => 5,
          "normal" => 5, "not" => 5, "overline" => 5, "placeholder" => 5,
          "subpixel" => 5, "tab" => 5, "text" => 5, "tracking" => 5,
          "underline" => 5, "uppercase" => 5, "whitespace" => 5, "word" => 5,
          # Backgrounds
          "bg" => 6, "from" => 6, "gradient" => 6, "to" => 6, "via" => 6,
          # Borders
          "border" => 7, "divide" => 7, "outline" => 7, "ring" => 7,
          "rounded" => 7,
          # Effects
          "mix" => 8, "opacity" => 8, "shadow" => 8,
          # Filters
          "backdrop" => 9, "blur" => 9, "brightness" => 9, "contrast" => 9,
          "drop" => 9, "filter" => 9, "grayscale" => 9, "hue" => 9,
          "invert" => 9, "saturate" => 9, "sepia" => 9,
          # Transitions and Animations
          "animate" => 10, "delay" => 10, "duration" => 10, "ease" => 10,
          "transition" => 10,
          # Transforms
          "origin" => 11, "rotate" => 11, "scale" => 11, "skew" => 11,
          "transform" => 11, "translate" => 11,
          # Interactivity
          "appearance" => 12, "cursor" => 12, "pointer" => 12,
          "resize" => 12, "scroll" => 12, "select" => 12, "snap" => 12,
          "touch" => 12, "will" => 12,
          # SVG
          "fill" => 13, "stroke" => 13,
          # Accessibility
          "sr" => 14
        }.freeze #: Hash[String, Integer]

        def self.rewriter_name = "tailwind-class-sorter" #: String

        def self.description = "Sort Tailwind CSS classes by recommended order" #: String

        # @rbs override
        def rewrite(ast, _context)
          traverse(ast) do |node|
            sort_class_attribute(node) if node.is_a?(Herb::AST::HTMLAttributeNode)
            nil
          end
          ast
        end

        private

        # Sort the classes in a class attribute.
        #
        # Only purely static class attributes (all LiteralNode children) are
        # sorted. Attributes containing ERB interpolation are left unchanged.
        #
        # HTMLAttributeValueNode#children is a mutable Array, so sorted content
        # is applied in place by replacing children with a re-parsed LiteralNode.
        #
        # @rbs attr: Herb::AST::HTMLAttributeNode
        def sort_class_attribute(attr) #: void
          return unless class_attribute?(attr)
          return unless attr.value

          children = attr.value.children
          return unless children.all? { _1.is_a?(Herb::AST::LiteralNode) }

          class_text = children.map(&:content).join
          sorted_text = sort_classes(class_text)
          return if class_text.strip == sorted_text

          new_literal = reparse_literal_node(sorted_text)
          children.replace([new_literal]) if new_literal
        end

        # Re-parse a class string to produce a fresh LiteralNode with the
        # given content. Returns nil if parsing fails.
        #
        # @rbs content: String
        def reparse_literal_node(content) #: Herb::AST::LiteralNode?
          result = Herb.parse(%(<x class="#{content}"></x>), track_whitespace: true)
          return unless result.success?

          open_tag = result.value.children.first&.open_tag
          return unless open_tag

          attr = open_tag.children.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
          return unless attr&.value

          attr.value.children.first
        end

        # Return the sort priority for a Tailwind CSS class name.
        # Lower numbers sort earlier in the recommended order.
        # Classes with unknown prefixes receive priority 999 and sort last.
        #
        # @rbs class_name: String
        def tailwind_sort_key(class_name) #: Integer
          # Strip variant prefixes (e.g., "hover:bg-blue-500" → "bg-blue-500")
          effective_name = class_name.split(":").last || class_name

          # Extract the first segment before "-" as the prefix key
          prefix = effective_name.split("-").first || effective_name

          CLASS_GROUPS.fetch(prefix, 999)
        end

        # Check if an attribute node is a class attribute.
        #
        # @rbs attr: Herb::AST::HTMLAttributeNode
        def class_attribute?(attr) #: bool
          attr.name.children.any? { _1.is_a?(Herb::AST::LiteralNode) && _1.content == "class" }
        end

        # Sort a space-separated string of Tailwind CSS class names.
        #
        # @rbs classes: String
        def sort_classes(classes) #: String
          class_list = classes.strip.split(/\s+/)
          class_list.sort_by { [tailwind_sort_key(_1), _1] }.join(" ")
        end
      end
    end
  end
end
