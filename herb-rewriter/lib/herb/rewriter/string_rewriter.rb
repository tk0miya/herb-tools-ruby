# frozen_string_literal: true

module Herb
  module Rewriter
    # Abstract base class for string-based post-format rewriters.
    #
    # Receives the formatted string output from FormatPrinter and returns
    # a transformed string. Applied in the post phase of the formatting pipeline.
    #
    # Example use cases: ensuring trailing newline, normalizing line endings.
    class StringRewriter
      def self.rewriter_name #: String
        raise NotImplementedError, "#{name} must implement self.rewriter_name"
      end

      def self.description #: String
        raise NotImplementedError, "#{name} must implement self.description"
      end

      # Transform formatted string and return modified string.
      #
      # @rbs formatted: String
      # @rbs context: untyped
      def rewrite(formatted, context) #: String
        raise NotImplementedError, "#{self.class.name} must implement #rewrite"
      end
    end
  end
end
