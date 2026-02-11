# frozen_string_literal: true

module Herb
  module Lint
    # String utility methods for formatting and text manipulation.
    module StringUtils
      # Pluralizes a word based on count.
      #
      # @rbs count: Integer -- the count to determine singular/plural
      # @rbs singular: String -- the singular form of the word
      # @return String -- singular or plural form
      #
      # @example
      #   pluralize(1, "file") # => "file"
      #   pluralize(2, "file") # => "files"
      #   pluralize(0, "error") # => "errors"
      def pluralize(count, singular) #: String
        count == 1 ? singular : "#{singular}s"
      end

      module_function :pluralize
    end
  end
end
