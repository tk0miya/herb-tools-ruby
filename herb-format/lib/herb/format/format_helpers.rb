# rbs_inline: enabled
# frozen_string_literal: true

module Herb
  module Format
    # FormatHelpers module provides constants and helper functions for formatting.
    #
    # This module contains all the constants and helper functions used by the
    # FormatPrinter to make formatting decisions, analyze nodes, and determine
    # layout strategies.
    module FormatHelpers
      # HTML inline elements that should be kept on the same line when possible.
      # These elements typically don't start on a new line and flow with text.
      INLINE_ELEMENTS = Set.new(%w[
                                  a abbr acronym b bdo big br cite code dfn em hr i img kbd label
                                  map object q samp small span strong sub sup tt var del ins mark s u time wbr
                                ]).freeze #: Set[String]

      # Elements whose content should be preserved as-is without formatting.
      # These elements contain content where whitespace is significant.
      CONTENT_PRESERVING_ELEMENTS = Set.new(%w[script style pre textarea]).freeze #: Set[String]

      # Container elements that can have blank lines between children.
      # These are typically structural/semantic containers.
      SPACEABLE_CONTAINERS = Set.new(%w[
                                       div section article main header footer aside figure
                                       details summary dialog fieldset
                                     ]).freeze #: Set[String]

      # Attributes whose values are space-separated token lists.
      # These require special handling to ensure spaces around dynamic content.
      TOKEN_LIST_ATTRIBUTES = Set.new(%w[class data-controller data-action]).freeze #: Set[String]

      # Attributes that can be formatted (wrapped, normalized).
      # Key '*' applies to all elements, specific element names for element-specific attributes.
      FORMATTABLE_ATTRIBUTES = {
        "*" => ["class"],
        "img" => %w[srcset sizes]
      }.freeze #: Hash[String, Array[String]]

      # Regular expression matching ASCII whitespace characters.
      # Used for normalizing whitespace in text content.
      ASCII_WHITESPACE = /[ \t\n\r]+/ #: Regexp
    end
  end
end
