# frozen_string_literal: true

module Herb
  module Format
    # Content unit for text flow analysis.
    #
    # Represents a single unit of content when processing text flow in the
    # formatter. Different types determine how units interact with line
    # wrapping and spacing decisions.
    #
    # Types:
    # - :text  - Plain text (splittable at word boundaries)
    # - :inline - Inline HTML element (rendered as an atomic string)
    # - :erb   - ERB expression or tag (atomic, does not break flow)
    # - :block - Block-level element (breaks the text flow)
    ContentUnit = Data.define(
      :content,         #: String
      :type,            #: Symbol
      :is_atomic,       #: bool
      :breaks_flow,     #: bool
      :is_herb_disable  #: bool
    )

    # :nodoc:
    class ContentUnit
      # @rbs content: String
      # @rbs type: Symbol
      # @rbs is_atomic: bool
      # @rbs breaks_flow: bool
      # @rbs is_herb_disable: bool
      def initialize(content:, type: :text, is_atomic: false, breaks_flow: false, is_herb_disable: false) #: void
        super
      end
    end

    # Content unit paired with its originating AST node.
    #
    # Used when building content unit lists from child nodes so that the
    # original node is available for re-visiting (e.g. block elements that
    # break the text flow).
    ContentUnitWithNode = Data.define(
      :unit,  #: ContentUnit
      :node   #: Herb::AST::Node?
    )
  end
end
