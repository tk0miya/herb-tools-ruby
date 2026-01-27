# frozen_string_literal: true

module Herb
  module Core
    # Discovers files based on include/exclude patterns or explicit paths.
    #
    # @example Discover from patterns (no paths provided)
    #   discovery = Herb::Core::FileDiscovery.new(
    #     base_dir: Dir.pwd,
    #     include_patterns: ["**/*.html.erb"],
    #     exclude_patterns: ["vendor/**/*"]
    #   )
    #   files = discovery.discover
    #
    # @example Discover from explicit paths only
    #   files = discovery.discover(["app/views/users/show.html.erb"])
    #   files = discovery.discover(["app/views/users"])  # directory
    class FileDiscovery
      attr_reader :base_dir #: String
      attr_reader :include_patterns #: Array[String]
      attr_reader :exclude_patterns #: Array[String]

      # @rbs base_dir: String -- the base directory for file discovery
      # @rbs include_patterns: Array[String] -- glob patterns to include
      # @rbs exclude_patterns: Array[String] -- glob patterns to exclude
      def initialize(base_dir:, include_patterns:, exclude_patterns:) #: void
        @base_dir = base_dir
        @include_patterns = include_patterns
        @exclude_patterns = exclude_patterns
      end

      # Discovers files based on patterns or explicit paths.
      # - No paths: uses include_patterns with exclude filtering
      # - File paths: returns files directly without exclude filtering
      # - Directory paths: discovers files in directory with exclude filtering
      #
      # @rbs paths: Array[String] -- explicit paths (files or directories) to include
      def discover(paths = []) #: Array[String]
        discovered = paths.empty? ? discover_from_patterns : discover_from_paths(paths)
        discovered.map { |file| relative_path(file) }.sort
      end

      private

      def discover_from_patterns #: Set[String]
        result = Set.new
        include_patterns.each do |pattern|
          full_pattern = File.join(base_dir, pattern)
          Dir.glob(full_pattern).each { |file| result << file if File.file?(file) && !excluded?(file) }
        end
        result
      end

      # @rbs paths: Array[String]
      def discover_from_paths(paths) #: Set[String]
        result = Set.new
        paths.each do |path|
          full_path = File.expand_path(path, base_dir)
          collect_from_path(full_path, result)
        end
        result
      end

      # @rbs full_path: String
      # @rbs result: Set[String]
      def collect_from_path(full_path, result) #: void
        if File.file?(full_path)
          result << full_path
        elsif File.directory?(full_path)
          Dir.glob(File.join(full_path, "**", "*")).each do |file|
            result << file if File.file?(file) && !excluded?(file)
          end
        end
      end

      # @rbs file: String
      def excluded?(file) #: bool
        relative = relative_path(file)

        exclude_patterns.any? do |pattern|
          File.fnmatch?(pattern, relative, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        end
      end

      # @rbs file: String
      def relative_path(file) #: String
        Pathname.new(file).relative_path_from(Pathname.new(base_dir)).to_s
      end
    end
  end
end
