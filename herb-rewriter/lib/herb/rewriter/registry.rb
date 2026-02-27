# frozen_string_literal: true

module Herb
  module Rewriter
    # Central registry for rewriter classes.
    #
    # Maintains a catalog of built-in rewriters and allows registration of
    # custom rewriters. Custom rewriters registered after initialization shadow
    # built-ins of the same name.
    #
    # Built-in rewriters are opt-in only — the formatter never auto-applies
    # any rewriter. Built-ins are a static catalog used for name resolution
    # when the user lists rewriter names in .herb.yml.
    class Registry
      BUILTIN_AST_REWRITERS = [BuiltIns::TailwindClassSorter].freeze #: Array[singleton(ASTRewriter)]
      BUILTIN_STRING_REWRITERS = [].freeze #: Array[singleton(StringRewriter)]

      # @rbs @ast_rewriters: Hash[String, singleton(ASTRewriter)]
      # @rbs @string_rewriters: Hash[String, singleton(StringRewriter)]

      def initialize #: void
        @ast_rewriters = {}
        @string_rewriters = {}
        BUILTIN_AST_REWRITERS.each { register(_1) }
        BUILTIN_STRING_REWRITERS.each { register(_1) }
      end

      # Check whether a rewriter name is registered (built-in or custom).
      #
      # @rbs name: String
      def registered?(name) #: bool
        key = normalize_name(name)
        @ast_rewriters.key?(key) || @string_rewriters.key?(key)
      end

      # Resolve an AST rewriter class by name.
      #
      # Returns immediately if already registered (built-in or custom).
      # Otherwise attempts to +require+ the name, auto-discovers any new
      # ASTRewriter subclasses via ObjectSpace, registers them, and returns
      # the matching class if found.
      #
      # When +name+ is a file path (e.g. <tt>foo_gem/my_rewriter.rb</tt>), the
      # lookup key is the basename without extension (<tt>my_rewriter</tt>),
      # matching the convention that a rewriter's +rewriter_name+ equals the
      # stem of its filename.
      #
      # @rbs name: String
      def resolve_ast_rewriter(name) #: singleton(ASTRewriter)?
        key = normalize_name(name)
        return @ast_rewriters[key] if @ast_rewriters.key?(key)

        auto_discover(name)
        @ast_rewriters[key]
      end

      # Resolve a String rewriter class by name.
      #
      # Returns immediately if already registered (built-in or custom).
      # Otherwise attempts to +require+ the name, auto-discovers any new
      # StringRewriter subclasses via ObjectSpace, registers them, and returns
      # the matching class if found.
      #
      # When +name+ is a file path (e.g. <tt>foo_gem/my_rewriter.rb</tt>), the
      # lookup key is the basename without extension (<tt>my_rewriter</tt>),
      # matching the convention that a rewriter's +rewriter_name+ equals the
      # stem of its filename.
      #
      # @rbs name: String
      def resolve_string_rewriter(name) #: singleton(StringRewriter)?
        key = normalize_name(name)
        return @string_rewriters[key] if @string_rewriters.key?(key)

        auto_discover(name)
        @string_rewriters[key]
      end

      private

      # @rbs klass: singleton(ASTRewriter) | singleton(StringRewriter)
      def register(klass) #: void
        if klass < ASTRewriter
          @ast_rewriters[klass.rewriter_name] = klass
        elsif klass < StringRewriter
          @string_rewriters[klass.rewriter_name] = klass
        else
          raise ArgumentError, "Rewriter must inherit from ASTRewriter or StringRewriter"
        end
      end

      # @rbs name: String
      def normalize_name(name) #: String
        File.basename(name, ".*")
      end

      # @rbs name: String
      def auto_discover(name) #: bool
        before = all_rewriter_subclasses
        require name
        (all_rewriter_subclasses - before).each { register(_1) }
        true
      rescue LoadError
        false
      end

      def all_rewriter_subclasses #: Array[singleton(ASTRewriter) | singleton(StringRewriter)]
        ObjectSpace.each_object(Class)
                   .select { _1 < ASTRewriter || _1 < StringRewriter }
                   .to_a
      end
    end
  end
end
