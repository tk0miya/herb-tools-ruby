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
          def initialize(severity: nil, options: nil) #: void
            super
            @inside_svg = false
          end

          # @rbs override
          def check(document, context) #: Array[Offense]
            @inside_svg = false
            super
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
              check_tag_capitalization(node, tag)
              super
            else
              super
            end
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs tag: String -- normalized lowercase tag name
          def check_tag_capitalization(node, tag) #: void
            correct_name = SVG_ELEMENTS[tag]
            return unless correct_name

            raw_tag = raw_tag_name(node)
            return unless raw_tag && raw_tag != correct_name

            # This is a known SVG element with incorrect capitalization
            add_offense(
              message: "SVG element '#{raw_tag}' should be '#{correct_name}'",
              location: node.tag_name.location
            )
          end
        end
      end
    end
  end
end
