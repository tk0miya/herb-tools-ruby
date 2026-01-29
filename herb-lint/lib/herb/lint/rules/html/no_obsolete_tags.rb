# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module Html
        # Rule that disallows obsolete HTML tags.
        #
        # Obsolete tags are no longer part of the HTML standard and should
        # be replaced with modern alternatives.
        #
        # Good:
        #   <strong>Bold text</strong>
        #   <div style="text-align: center">Centered</div>
        #
        # Bad:
        #   <center>Centered</center>
        #   <font color="red">Red text</font>
        #   <marquee>Scrolling text</marquee>
        class NoObsoleteTags < VisitorRule
          OBSOLETE_TAGS = %w[
            acronym
            applet
            basefont
            big
            blink
            center
            dir
            font
            frame
            frameset
            isindex
            keygen
            listing
            marquee
            menuitem
            multicol
            nextid
            nobr
            noembed
            noframes
            plaintext
            spacer
            strike
            tt
            xmp
          ].freeze

          def self.rule_name #: String
            "html/no-obsolete-tags"
          end

          def self.description #: String
            "Disallow obsolete HTML tags"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            tag_name = node.tag_name&.value&.downcase
            if tag_name && OBSOLETE_TAGS.include?(tag_name)
              add_offense(
                message: "The <#{tag_name}> tag is obsolete and should not be used",
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
