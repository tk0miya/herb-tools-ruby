# frozen_string_literal: true

module Herb
  module Format
    # Analysis result for HTMLElementNode formatting decisions.
    ElementAnalysis = Data.define(
      :open_tag_inline,         #: bool
      :element_content_inline,  #: bool
      :close_tag_inline         #: bool
    )

    # :nodoc:
    class ElementAnalysis
      # Element is fully inline (one line output)
      def fully_inline? #: bool
        open_tag_inline && element_content_inline && close_tag_inline
      end

      # Element uses block formatting
      def block_format? #: bool
        !element_content_inline
      end
    end
  end
end
