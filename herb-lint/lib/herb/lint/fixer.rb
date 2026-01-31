# frozen_string_literal: true

module Herb
  module Lint
    # Applies automatic fixes from offense fix procs to source code.
    #
    # Fixes are applied in reverse document order (end of file first) to
    # maintain correct character positions for earlier fixes.
    class Fixer
      attr_reader :source #: String
      attr_reader :offenses #: Array[Offense]
      attr_reader :fix_unsafely #: bool

      # @rbs source: String -- original source code
      # @rbs offenses: Array[Offense] -- offenses to attempt to fix
      # @rbs fix_unsafely: bool -- when true, also apply unsafe fixes
      def initialize(source, offenses, fix_unsafely: false) #: void
        @source = source
        @offenses = offenses
        @fix_unsafely = fix_unsafely
      end

      # Apply all applicable fixes and return the modified source.
      # Returns the original source if no fixes are applicable.
      def apply_fixes #: String
        fixes = fixable_offenses
        return source if fixes.empty?

        sorted = sort_by_location(fixes)
        current_source = source.dup

        sorted.each do |offense|
          current_source = apply_fix(offense, current_source)
        end

        current_source
      end

      private

      # Filter offenses to those that can be fixed.
      # When fix_unsafely is false, excludes unsafe fixes.
      def fixable_offenses #: Array[Offense]
        offenses.select do |offense|
          offense.fixable? && (fix_unsafely || !offense.unsafe)
        end
      end

      # Sort offenses in reverse document order (end of file first).
      # This ensures that applying fixes doesn't invalidate the positions
      # of subsequent fixes.
      def sort_by_location(offenses) #: Array[Offense]
        offenses.sort_by { |o| [-o.location.start.line, -o.location.start.column] }
      end

      # Apply a single offense's fix proc to the source.
      # @rbs offense: Offense
      # @rbs current_source: String
      def apply_fix(offense, current_source) #: String
        offense.fix.call(current_source) # steep:ignore
      end
    end
  end
end
