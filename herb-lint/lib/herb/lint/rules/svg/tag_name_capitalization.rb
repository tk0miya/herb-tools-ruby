# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/svg-tag-name-capitalization.ts
# Documentation: https://herb-tools.dev/linter/rules/svg-tag-name-capitalization

module Herb
  module Lint
    module Rules
      module Svg
        # Rule that enforces correct capitalization of SVG element names.
        #
        # SVG is case-sensitive and uses camelCase for many element names,
        # unlike HTML which is case-insensitive. This rule ensures SVG elements
        # use the correct capitalization.
        #
        # Good:
        #   <svg>
        #     <clipPath id="clip">
        #       <rect width="100" height="100"/>
        #     </clipPath>
        #     <linearGradient id="grad">
        #       <stop offset="0%" stop-color="red"/>
        #     </linearGradient>
        #   </svg>
        #
        # Bad:
        #   <svg>
        #     <clippath id="clip">
        #       <rect width="100" height="100"/>
        #     </clippath>
        #     <lineargradient id="grad">
        #       <stop offset="0%" stop-color="red"/>
        #     </lineargradient>
        #   </svg>
        class TagNameCapitalization < VisitorRule
          def self.rule_name #: String
            "svg-tag-name-capitalization"
          end

          def self.description #: String
            "Enforce correct capitalization of SVG element names"
          end

          def self.default_severity #: String
            "warning"
          end

          def self.safe_autofixable? #: bool
            true
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # SVG elements that require specific capitalization (camelCase).
          # Maps lowercase version to correct capitalization.
          SVG_ELEMENTS = {
            "animatemotion" => "animateMotion",
            "animatetransform" => "animateTransform",
            "clippath" => "clipPath",
            "feblend" => "feBlend",
            "fecolormatrix" => "feColorMatrix",
            "fecomponenttransfer" => "feComponentTransfer",
            "fecomposite" => "feComposite",
            "feconvolvematrix" => "feConvolveMatrix",
            "fediffuselighting" => "feDiffuseLighting",
            "fedisplacementmap" => "feDisplacementMap",
            "fedistantlight" => "feDistantLight",
            "fedropshadow" => "feDropShadow",
            "feflood" => "feFlood",
            "fefunca" => "feFuncA",
            "fefuncb" => "feFuncB",
            "fefuncg" => "feFuncG",
            "fefuncr" => "feFuncR",
            "fegaussianblur" => "feGaussianBlur",
            "feimage" => "feImage",
            "femerge" => "feMerge",
            "femergenode" => "feMergeNode",
            "femorphology" => "feMorphology",
            "feoffset" => "feOffset",
            "fepointlight" => "fePointLight",
            "fespecularlighting" => "feSpecularLighting",
            "fespotlight" => "feSpotLight",
            "fetile" => "feTile",
            "feturbulence" => "feTurbulence",
            "foreignobject" => "foreignObject",
            "lineargradient" => "linearGradient",
            "radialgradient" => "radialGradient",
            "textpath" => "textPath"
          }.freeze

          # @rbs @inside_svg: bool

          # @rbs override
          def on_new_investigation #: void
            super
            @inside_svg = false
          end

          # @rbs override
          def visit_html_element_node(node)
            tag = tag_name(node)

            if tag == "svg"
              previous_inside_svg = @inside_svg
              @inside_svg = true
              super
              @inside_svg = previous_inside_svg
            elsif @inside_svg && tag
              check_tag(node.open_tag, tag, "Opening") if node.open_tag
              check_tag(node.close_tag, tag, "Closing") if node.close_tag
              super
            else
              super
            end
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode | Herb::AST::HTMLCloseTagNode
          # @rbs parse_result: Herb::ParseResult -- the parse result from the lint phase
          def autofix(node, parse_result) #: bool
            tag_name = node.tag_name.value
            return false unless tag_name

            correct_name = SVG_ELEMENTS[tag_name.downcase]
            return false unless correct_name

            new_tag_name_token = copy_token(node.tag_name, content: correct_name)
            new_node = copy_erb_node(node, tag_name: new_tag_name_token)
            replace_node(parse_result, node, new_node)
          end

          private

          # @rbs node: Herb::AST::HTMLOpenTagNode | Herb::AST::HTMLCloseTagNode
          # @rbs tag: String -- normalized lowercase tag name
          # @rbs prefix: String -- "Opening" or "Closing"
          def check_tag(node, tag, prefix) #: void
            correct_name = SVG_ELEMENTS[tag]
            return unless correct_name

            raw_tag = node.tag_name&.value
            return unless raw_tag && raw_tag != correct_name

            add_offense_with_autofix(
              message: "#{prefix} SVG element '#{raw_tag}' should be '#{correct_name}'",
              location: node.tag_name.location,
              node:
            )
          end
        end
      end
    end
  end
end
