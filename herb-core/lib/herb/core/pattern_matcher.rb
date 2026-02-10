# frozen_string_literal: true

module Herb
  module Core
    # Matches file paths against include, exclude, and only patterns.
    # Used for verifying file match conditions in herb.yml rule configurations.
    #
    # @example Basic usage
    #   matcher = Herb::Core::PatternMatcher.new(
    #     includes: ["**/*.erb"],
    #     excludes: ["vendor/**"],
    #     only: []
    #   )
    #   matcher.match?("app/views/users/show.html.erb")  # => true
    #   matcher.match?("vendor/views/index.html.erb")    # => false
    #
    # @example With only patterns
    #   matcher = Herb::Core::PatternMatcher.new(
    #     includes: [],
    #     excludes: [],
    #     only: ["app/views/**"]
    #   )
    #   matcher.match?("app/views/users/show.html.erb")  # => true
    #   matcher.match?("lib/views/index.html.erb")       # => false
    class PatternMatcher
      # @rbs includes: Array[String] -- glob patterns to include
      # @rbs excludes: Array[String] -- glob patterns to exclude
      # @rbs only: Array[String] -- glob patterns to exclusively match
      def initialize(includes:, excludes:, only:) #: void
        @includes = includes.map { normalize_pattern(_1) }
        @excludes = excludes.map { normalize_pattern(_1) }
        @only = only.map { normalize_pattern(_1) }
      end

      # Checks if a file path matches the configured patterns.
      #
      # Matching logic (matches TypeScript implementation):
      # 1. If only patterns are specified, path must match at least one
      # 2. If include patterns are specified (and no only), path must match at least one
      # 3. If path matches any exclude pattern, return false
      # 4. If no patterns are specified, return true (match all)
      #
      # @rbs path: String -- the file path to check (relative or absolute)
      # @rbs return: bool
      def match?(path) #: bool
        # Only patterns are exclusive - if specified, path must match one
        if !@only.empty?
          return false if @only.none? { matches?(path, _1) }
        # Include patterns - checked only when no only patterns
        elsif !@includes.empty?
          return false if @includes.none? { matches?(path, _1) }
        end

        # Exclude patterns are always applied last
        return false if @excludes.any? { matches?(path, _1) }

        # No patterns specified or all checks passed
        true
      end

      private

      # Normalizes glob patterns for consistent matching behavior.
      # Patterns ending with ** are expanded to **/* to match files.
      # @rbs pattern: String
      # @rbs return: String
      def normalize_pattern(pattern) #: String
        # Pattern ends with /** -> convert to /**/*
        return "#{pattern}/*" if pattern.end_with?("/**")

        # Pattern ends with ** -> convert to **/*
        return "#{pattern}/*" if pattern.end_with?("**")

        pattern
      end

      # Checks if a path matches a single pattern.
      # @rbs path: String
      # @rbs pattern: String
      # @rbs return: bool
      def matches?(path, pattern) #: bool
        File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
      end
    end
  end
end
