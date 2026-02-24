# frozen_string_literal: true

module Herb
  module Format
    # Central registry for rewriter classes (Registry Pattern).
    class RewriterRegistry
      # @rbs @rewriters: Hash[String, singleton(Rewriters::Base)]

      def initialize #: void
        @rewriters = {}
      end

      # Register a rewriter class.
      #
      # @rbs rewriter_class: singleton(Rewriters::Base)
      def register(rewriter_class) #: void
        validate_rewriter_class(rewriter_class)
        name = rewriter_class.rewriter_name
        @rewriters[name] = rewriter_class
      end

      # Get a rewriter class by name.
      #
      # @rbs name: String
      def get(name) #: singleton(Rewriters::Base)?
        @rewriters[name]
      end

      # Check if a rewriter is registered.
      #
      # @rbs name: String
      def registered?(name) #: bool
        @rewriters.key?(name)
      end

      # Get all registered rewriter classes.
      def all #: Array[singleton(Rewriters::Base)]
        @rewriters.values
      end

      # Get all registered rewriter names.
      def rewriter_names #: Array[String]
        @rewriters.keys
      end

      # Load built-in rewriters.
      # TODO: require and register built-in rewriters once implemented (Tasks 4.3-4.5)
      def load_builtin_rewriters #: void
      end

      private

      # @rbs rewriter_class: singleton(Rewriters::Base)
      def validate_rewriter_class(rewriter_class) #: bool
        unless rewriter_class < Rewriters::Base
          raise Errors::RewriterError, "Rewriter must inherit from Rewriters::Base"
        end

        # Ensure required class methods are implemented
        rewriter_class.rewriter_name
        rewriter_class.description
        rewriter_class.phase

        true
      rescue NoMethodError, NotImplementedError => e
        raise Errors::RewriterError, "Rewriter class missing required method: #{e.message}"
      end
    end
  end
end
