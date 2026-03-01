# frozen_string_literal: true

module Herb
  module Format
    # Orchestrates the formatting process across multiple files.
    class Runner
      # @rbs @formatter: Formatter
      # @rbs @rewriter_registry: Herb::Rewriter::Registry

      attr_reader :check  #: bool
      attr_reader :config #: Herb::Config::FormatterConfig
      attr_reader :force  #: bool

      # @rbs config: Herb::Config::FormatterConfig
      # @rbs check: bool
      # @rbs force: bool
      def initialize(config:, check: false, force: false) #: void
        @config = config
        @check = check
        @force = force
        @rewriter_registry = Herb::Rewriter::Registry.new
        @formatter = build_formatter
      end

      # Run formatting on files and return aggregated result.
      #
      # @rbs files: Array[String]?
      def run(files = nil) #: AggregatedResult
        target_files = discover_files(files)
        results = target_files.map { format_file(_1) }

        AggregatedResult.new(results:)
      end

      # Format source string directly (for stdin mode).
      #
      # @rbs source: String
      # @rbs file_path: String
      def format_source(source, file_path:) #: FormatResult
        @formatter.format(file_path, source, force:)
      end

      private

      def build_formatter #: Formatter
        factory = FormatterFactory.new(config, @rewriter_registry)
        factory.create
      end

      # Discover files to format.
      # If files is nil or empty, use config include/exclude patterns.
      # If files is provided, use those paths directly (still respecting exclude).
      #
      # @rbs files: Array[String]?
      def discover_files(files) #: Array[String]
        if files.nil? || files.empty?
          discovery = Herb::Core::FileDiscovery.new(
            base_dir: Dir.pwd,
            include_patterns: config.include_patterns,
            exclude_patterns: config.exclude_patterns
          )
          discovery.discover
        else
          files.reject { excluded?(_1) }
        end
      end

      # @rbs file: String
      def excluded?(file) #: bool
        config.exclude_patterns.any? { File.fnmatch?(_1, file, File::FNM_PATHNAME) }
      end

      # @rbs file_path: String
      def format_file(file_path) #: FormatResult
        source = File.read(file_path)
        result = @formatter.format(file_path, source, force:)

        write_file(result) if !check && result.changed? && !result.ignored? && !result.error?

        result
      rescue StandardError => e
        FormatResult.new(
          file_path:,
          original: "",
          formatted: "",
          error: e
        )
      end

      # @rbs result: FormatResult
      def write_file(result) #: void
        File.write(result.file_path, result.formatted)
      end
    end
  end
end
