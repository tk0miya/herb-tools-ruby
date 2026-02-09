# frozen_string_literal: true

module Herb
  module Config
    # Handles file pattern matching for rules.
    # Evaluates paths relative to base_dir.
    class PatternMatcher
      attr_reader :base_dir, :include_patterns, :exclude_patterns, :only_patterns

      # @rbs base_dir: String
      # @rbs include: Array[String]
      # @rbs exclude: Array[String]
      # @rbs only: Array[String]
      def initialize(base_dir:, include: [], exclude: [], only: []) #: void
        @base_dir = base_dir
        @include_patterns = include
        @exclude_patterns = exclude
        @only_patterns = only
      end

      # Check if the given file path matches the patterns.
      # @rbs file_path: String -- relative path from base_dir
      # @rbs return: bool
      def match?(file_path) #: bool
        return false unless passes_only_check?(file_path)
        return false unless passes_include_check?(file_path)
        return false if matches_exclude?(file_path)

        true
      end

      private

      # Check if file passes 'only' pattern restrictions
      # @rbs file_path: String
      def passes_only_check?(file_path) #: bool
        return true if only_patterns.empty?

        matches_any?(only_patterns, file_path)
      end

      # Check if file passes include pattern requirements
      # @rbs file_path: String
      def passes_include_check?(file_path) #: bool
        return true if only_patterns.any? # Skip include check if 'only' is used
        return true if include_patterns.empty?

        matches_any?(include_patterns, file_path)
      end

      # Check if file matches any exclude patterns
      # @rbs file_path: String
      def matches_exclude?(file_path) #: bool
        matches_any?(exclude_patterns, file_path)
      end

      # Check if file matches any pattern in the list
      # @rbs patterns: Array[String]
      # @rbs file_path: String
      def matches_any?(patterns, file_path) #: bool
        patterns.any? { |pattern| File.fnmatch?(pattern, file_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end
    end
  end
end
