# frozen_string_literal: true

require_relative "rule_methods"

module Herb
  module Lint
    module Rules
      # Abstract base class for rules that operate on raw source strings
      # rather than the AST.
      #
      # Subclasses must implement:
      # - check_source(source, context)
      #
      # Subclasses may optionally override:
      # - autofix_source(offense, source)
      #
      # For rules that traverse the AST using the visitor pattern,
      # use VisitorRule instead.
      class SourceRule
        include RuleMethods

        # @rbs!
        #   extend RuleMethods::ClassMethods

        # @rbs override
        def check(_parse_result, context)
          @offenses = []
          @context = context
          @source = context.source
          on_new_investigation
          check_source(@source, context)
          @offenses
        end

        # Check the source string for rule violations.
        # Subclasses must implement this method.
        #
        # @rbs _source: String -- raw source string to check
        # @rbs _context: Context -- linting context with file information
        def check_source(_source, _context) #: void
          raise NotImplementedError, "#{self.class.name} must implement #check_source"
        end

        # Apply autofix to the source string.
        # Override in autofixable rules to perform source-level fixes.
        # Returns the fixed source string, or nil if the fix cannot be applied.
        #
        # @rbs _offense: Offense -- the offense to fix
        # @rbs _source: String -- the current source string
        def autofix_source(_offense, _source) #: String?
          nil
        end

        protected

        # Called at the start of each investigation to allow rules to reset state.
        # Subclasses should override this method to reset any instance variables
        # that accumulate state during source checking.
        #
        # This hook is inspired by RuboCop's on_new_investigation pattern.
        # @rbs override
        def on_new_investigation #: void
          # Default implementation does nothing
          # Subclasses can override to reset state
        end

        private

        # @rbs @source: String

        # Add an offense with source-level autofix context.
        # Creates an AutofixContext with source offsets instead of AST nodes.
        #
        # @rbs message: String -- description of the violation
        # @rbs location: Herb::Location -- location of the violation
        # @rbs start_offset: Integer -- character offset where the offense starts
        # @rbs end_offset: Integer -- character offset where the offense ends
        def add_offense_with_source_autofix(message:, location:, start_offset:, end_offset:) #: void
          context = AutofixContext.new(rule: self, start_offset:, end_offset:)
          add_offense(message:, location:, autofix_context: context)
        end

        # Create a location object from character offsets.
        # @rbs start_offset: Integer
        # @rbs end_offset: Integer
        def location_from_offsets(start_offset, end_offset) #: Herb::Location
          start_pos = position_from_offset(start_offset)
          end_pos = position_from_offset(end_offset)

          Herb::Location.new(start_pos, end_pos)
        end

        # Convert character offset to line and column position (0-indexed).
        # @rbs offset: Integer
        def position_from_offset(offset) #: Herb::Position
          line = 0
          column = 0
          current_offset = 0

          @source.each_char do |char|
            break if current_offset >= offset

            if char == "\n"
              line += 1
              column = 0
            else
              column += 1
            end
            current_offset += 1
          end

          Herb::Position.new(line, column)
        end
      end
    end
  end
end
