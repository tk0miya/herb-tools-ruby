# frozen_string_literal: true

module Herb
  module Format
    # Central registry for rewriter classes (Registry Pattern).
    #
    # NOTE: This class will be superseded by Herb::Rewriter::Registry
    # (from the herb-rewriter gem) in a later task. The built-in rewriter
    # registration has been moved to herb-rewriter.
    class RewriterRegistry
      # @rbs @rewriters: Hash[String, Class]

      def initialize #: void
        @rewriters = {}
      end

      # Get a rewriter class by name.
      #
      # @rbs name: String
      def get(name) #: Class?
        @rewriters[name]
      end

      # Load built-in rewriters.
      # Built-in rewriters are now registered via Herb::Rewriter::Registry.
      def load_builtin_rewriters #: void
        # Built-ins moved to herb-rewriter gem (Herb::Rewriter::Registry)
      end

      # Require rewriter files from the given require names.
      # @rbs names: Array[String] -- require names (gem names or file paths)
      def load_custom_rewriters(names) #: void
        names.each { require _1 }
      end
    end
  end
end
