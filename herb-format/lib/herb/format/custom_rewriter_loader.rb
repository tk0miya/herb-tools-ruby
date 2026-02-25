# frozen_string_literal: true

module Herb
  module Format
    # Loads custom rewriter implementations from configured paths.
    class CustomRewriterLoader
      DEFAULT_PATH = ".herb/rewriters" #: String

      attr_reader :config #: Herb::Config::FormatterConfig
      attr_reader :registry #: RewriterRegistry

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs registry: RewriterRegistry
      def initialize(config, registry) #: void
        @config = config
        @registry = registry
      end

      def load #: void
        load_rewriters_from(DEFAULT_PATH)
      end

      private

      # @rbs path: String
      def load_rewriters_from(path) #: void
        return unless Dir.exist?(path)

        Dir.glob(File.join(path, "*.rb")).each { require_rewriter_file(_1) }

        auto_register_rewriters
      rescue StandardError => e
        warn "Failed to load custom rewriters from #{path}: #{e.message}"
      end

      # @rbs file_path: String
      def require_rewriter_file(file_path) #: void
        require File.expand_path(file_path)
      rescue LoadError, StandardError => e
        warn "Failed to load rewriter file #{file_path}: #{e.message}"
      end

      def auto_register_rewriters #: void
        Rewriters.constants.each do |const_name|
          const = Rewriters.const_get(const_name)
          next unless const.is_a?(Class) && const < Rewriters::Base
          next if registry.registered?(const.rewriter_name)

          registry.register(const)
        rescue StandardError => e
          warn "Failed to register rewriter #{const_name}: #{e.message}"
        end
      end
    end
  end
end
