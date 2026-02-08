# frozen_string_literal: true

require "herb/printer"

module Herb
  module Lint
    # Orchestrates autofix application for a single file.
    # Receives the ParseResult from the lint phase (single-parse design)
    # and applies fixes to the same AST.
    class AutoFixer
      attr_reader :offenses #: Array[Offense]
      attr_reader :parse_result #: Herb::ParseResult?
      attr_reader :unsafe #: bool

      # @rbs parse_result: Herb::ParseResult? -- the parse result from the lint phase (nil on parse error)
      # @rbs offenses: Array[Offense] -- offenses detected during linting
      # @rbs unsafe: bool -- when true, also apply unsafe autofixes
      def initialize(parse_result, offenses, unsafe: false) #: void
        @parse_result = parse_result
        @offenses = offenses
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
      # 2. Apply AST-phase autofixes for autofixable offenses
      # 3. Return AutoFixResult with corrected source and categorized offenses
      def apply #: AutoFixResult
        autofixable, non_autofixable = offenses.partition { _1.autofixable?(unsafe:) }

        source, fixed, unfixed = apply_fixes(autofixable)

        AutoFixResult.new(source:, fixed:, unfixed: non_autofixable + unfixed)
      end

      private

      # Apply autofixes for autofixable offenses.
      # For each offense, instantiate the rule and call its autofix method.
      # After all fixes, serialize the modified AST via IdentityPrinter.
      #
      # @rbs offenses: Array[Offense] -- autofixable offenses to apply
      def apply_fixes(offenses) #: [String, Array[Offense], Array[Offense]]
        fixed = [] #: Array[Offense]
        unfixed = [] #: Array[Offense]

        offenses.each do |offense|
          context = offense.autofix_context
          unless context
            unfixed << offense
            next
          end

          rule = context.rule_class.new
          success = rule.autofix(context.node, parse_result)

          if success
            fixed << offense
          else
            unfixed << offense
          end
        end

        source = Herb::Printer::IdentityPrinter.print(parse_result)
        [source, fixed, unfixed]
      end
    end
  end
end
