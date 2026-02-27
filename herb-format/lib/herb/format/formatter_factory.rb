# frozen_string_literal: true

module Herb
  module Format
    # Creates configured Formatter instances (Factory Pattern).
    #
    # Queries a RewriterRegistry to instantiate pre- and post-rewriters by name,
    # then assembles a Formatter with the resolved instances.
    class FormatterFactory
      attr_reader :config #: Herb::Config::FormatterConfig
      attr_reader :rewriter_registry #: Herb::Rewriter::Registry

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs rewriter_registry: Herb::Rewriter::Registry
      def initialize(config, rewriter_registry) #: void
        @config = config
        @rewriter_registry = rewriter_registry
      end

      # Create a configured Formatter instance.
      #
      # Resolves pre- and post-rewriter names from config via the registry,
      # then instantiates them and passes the result to Formatter.
      def create #: Formatter
        pre_rewriters = build_pre_rewriters
        post_rewriters = build_post_rewriters

        Formatter.new(pre_rewriters, post_rewriters, config)
      end

      private

      def build_pre_rewriters #: Array[Herb::Rewriter::ASTRewriter]
        config.rewriter_pre.filter_map { instantiate_ast_rewriter(_1) }
      end

      def build_post_rewriters #: Array[Herb::Rewriter::StringRewriter]
        config.rewriter_post.filter_map { instantiate_string_rewriter(_1) }
      end

      # @rbs name: String
      def instantiate_ast_rewriter(name) #: Herb::Rewriter::ASTRewriter?
        rewriter_class = rewriter_registry.resolve_ast_rewriter(name)
        unless rewriter_class
          warn "Pre-format rewriter '#{name}' not found. Skipping."
          return nil
        end

        rewriter_class.new
      rescue StandardError => e
        warn "Failed to instantiate pre-format rewriter '#{name}': #{e.message}"
        nil
      end

      # @rbs name: String
      def instantiate_string_rewriter(name) #: Herb::Rewriter::StringRewriter?
        rewriter_class = rewriter_registry.resolve_string_rewriter(name)
        unless rewriter_class
          warn "Post-format rewriter '#{name}' not found. Skipping."
          return nil
        end

        rewriter_class.new
      rescue StandardError => e
        warn "Failed to instantiate post-format rewriter '#{name}': #{e.message}"
        nil
      end
    end
  end
end
