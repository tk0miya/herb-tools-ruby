# frozen_string_literal: true

require "herb/printer"

module Herb
  module Lint
    # Orchestrates autofix application for a single file.
    # Receives the ParseResult from the lint phase (single-parse design)
    # and applies fixes to the same AST.
    class Autofixer
      attr_reader :offenses #: Array[Offense]
      attr_reader :parse_result #: Herb::ParseResult?
      attr_reader :source #: String
      attr_reader :unsafe #: bool

      # @rbs parse_result: Herb::ParseResult? -- the parse result from the lint phase (nil on parse error)
      # @rbs offenses: Array[Offense] -- offenses detected during linting
      # @rbs source: String -- the original source code
      # @rbs unsafe: bool -- when true, also apply unsafe autofixes
      def initialize(parse_result, offenses, source:, unsafe: false) #: void
        @parse_result = parse_result
        @offenses = offenses
        @source = source
        @unsafe = unsafe
      end

      # Returns true when there are any autofixable offenses.
      # Requires a valid parse_result and at least one offense that can be autocorrected.
      #
      # @rbs unsafe: bool -- when true, also consider unsafe autofixes
      def autofixable?(unsafe:) #: boolish
        return false unless parse_result

        offenses.any? { _1.autofixable?(unsafe:) }
      end

      # Apply autofixes and return the result.
      #
      # Processing:
      # 1. Partition offenses into autofixable and non-autofixable
      # 2. Partition autofixable offenses into AST-based (visitor rules) and source-based (source rules)
      # 3. Apply AST-phase autofixes first
      # 4. Apply source-phase autofixes to the resulting source
      # 5. Return AutoFixResult with corrected source and categorized offenses
      def apply #: AutoFixResult
        autofixable, non_autofixable = offenses.partition { _1.autofixable?(unsafe:) }

        # Partition by rule type: visitor rules operate on AST, source rules operate on source string
        ast_fixable, source_fixable = autofixable.partition { _1.autofix_context&.visitor_rule? }

        # Apply AST fixes first, serialize to source
        source, ast_fixed, ast_unfixed = apply_ast_fixes(ast_fixable)

        # Apply source fixes to the resulting source
        source, src_fixed, src_unfixed = apply_source_fixes(source_fixable, source)

        AutoFixResult.new(
          source:,
          fixed: ast_fixed + src_fixed,
          unfixed: non_autofixable + ast_unfixed + src_unfixed
        )
      end

      private

      # Apply AST-based autofixes for visitor rule offenses.
      # For each offense, use the cached rule instance to call its autofix method.
      # After all fixes, serialize the modified AST via IdentityPrinter.
      #
      # @rbs offenses: Array[Offense] -- autofixable visitor rule offenses
      def apply_ast_fixes(offenses) #: [String, Array[Offense], Array[Offense]]
        fixed = [] #: Array[Offense]
        unfixed = [] #: Array[Offense]

        offenses.each do |offense|
          context = offense.autofix_context
          unless context
            unfixed << offense
            next
          end

          success = context.rule.autofix(context.node, parse_result)

          if success
            fixed << offense
          else
            unfixed << offense
          end
        end

        # If no fixes were applied, return the original source to preserve formatting
        result_source = fixed.empty? ? source : Herb::Printer::IdentityPrinter.print(parse_result)
        [result_source, fixed, unfixed]
      end

      # Apply source-based autofixes for source rule offenses.
      # For each offense, call the rule's autofix_source method sequentially.
      # Fixes are applied from end to start (by descending end_offset) to avoid
      # invalidating subsequent offsets.
      #
      # @rbs offenses: Array[Offense] -- autofixable source rule offenses
      # @rbs source: String -- the source code to apply fixes to
      def apply_source_fixes(offenses, source) #: [String, Array[Offense], Array[Offense]]
        fixed = [] #: Array[Offense]
        unfixed = [] #: Array[Offense]

        current_source = source

        # Sort by end_offset descending (apply from end to start to preserve offsets)
        sorted_offenses = offenses.sort_by { -(_1.autofix_context&.end_offset || 0) }

        sorted_offenses.each do |offense|
          context = offense.autofix_context
          unless context
            unfixed << offense
            next
          end

          # Call the rule's autofix_source method
          new_source = context.rule.autofix_source(offense, current_source)

          if new_source
            current_source = new_source
            fixed << offense
          else
            unfixed << offense
          end
        end

        [current_source, fixed, unfixed]
      end
    end
  end
end
