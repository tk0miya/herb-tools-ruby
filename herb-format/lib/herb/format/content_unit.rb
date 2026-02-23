# frozen_string_literal: true

module Herb
  module Format
    # Content unit for text flow analysis.
    #
    # Represents a unit of content with metadata about how it should be
    # handled during text flow processing and word wrapping.
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
      def initialize( # rubocop:disable Metrics/ParameterLists
        content:,
        type: :text,
        is_atomic: false,
        breaks_flow: false,
        is_herb_disable: false
      ) #: void
        super(
          content: content,
          type: type,
          is_atomic: is_atomic,
          breaks_flow: breaks_flow,
          is_herb_disable: is_herb_disable
        )
      end
    end

    # Content unit with its associated AST node.
    #
    # Pairs a ContentUnit with the original AST node for cases where
    # the node needs to be visited directly (e.g. block elements).
    ContentUnitWithNode = Data.define(
      :unit,  #: ContentUnit
      :node   #: Herb::AST::Node?
    )
  end
end
