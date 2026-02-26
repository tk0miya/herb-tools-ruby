# frozen_string_literal: true

module Herb
  module Format
    # Central registry for rewriter classes (Registry Pattern).
    class RewriterRegistry
      # @rbs @rewriters: Hash[String, singleton(Rewriters::Base)]

      def initialize #: void
        @rewriters = {}
      end

      # Get a rewriter class by name.
      #
      # @rbs name: String
      def get(name) #: singleton(Rewriters::Base)?
        @rewriters[name]
      end

      # Load built-in rewriters.
      def load_builtin_rewriters #: void
        register(Rewriters::TailwindClassSorter)
      end

      # Load and register custom rewriters from the given require names.
      # Each name is passed to Kernel#require. Any newly defined rewriter classes
      # are automatically discovered via ObjectSpace and registered.
      # @rbs names: Array[String] -- require names (gem names or file paths)
      def load_custom_rewriters(names) #: void
        return if names.empty?

        before = all_rewriter_subclasses
        names.each { require _1 }
        (all_rewriter_subclasses - before).each { register(_1) }
      end

      private

      # @rbs rewriter_class: singleton(Rewriters::Base)
      def register(rewriter_class) #: void
        validate_rewriter_class(rewriter_class)
        name = rewriter_class.rewriter_name
        @rewriters[name] = rewriter_class
      end

      # Returns all currently loaded rewriter subclasses via ObjectSpace.
      # Used to detect newly defined rewriters after requiring custom rewriter files.
      def all_rewriter_subclasses #: Array[singleton(Rewriters::Base)]
        ObjectSpace.each_object(Class)
                   .select { _1 < Rewriters::Base }
                   .to_a
      end

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
