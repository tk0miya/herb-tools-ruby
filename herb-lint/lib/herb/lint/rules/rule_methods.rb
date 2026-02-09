# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      # Common functionality for all lint rules.
      # Include this module in rule classes to get rule metadata and offense creation.
      module RuleMethods
        # @rbs base: Class
        def self.included(base) #: void
          base.extend(ClassMethods)
          base.attr_reader :severity #: String
          base.attr_reader :matcher #: Herb::Config::PatternMatcher?
        end

        # Class methods for rule metadata.
        module ClassMethods
          def rule_name #: String
            raise NotImplementedError, "#{name} must implement .rule_name"
          end

          def description #: String
            raise NotImplementedError, "#{name} must implement .description"
          end

          def default_severity #: String
            "warning"
          end

          # Whether the rule provides safe autofix.
          def safe_autofixable? #: bool
            false
          end

          # Whether the rule provides unsafe autofix (requires --fix-unsafely).
          def unsafe_autofixable? #: bool
            false
          end
        end

        # @rbs severity: String?
        # @rbs matcher: Herb::Config::PatternMatcher?
        def initialize(severity: nil, matcher: nil) #: void
          @severity = severity || self.class.default_severity
          @matcher = matcher
          super() if defined?(super)
        end

        # @rbs @offenses: Array[Offense]
        # @rbs @context: Context

        # Check the document for rule violations.
        #
        # @rbs document: Herb::ParseResult -- parsed document to check
        # @rbs context: Context -- linting context with file information
        def check(document, context) #: Array[Offense]
          raise NotImplementedError, "#{self.class.name} must implement #check"
        end

        # Add an offense for the current rule.
        #
        # @rbs message: String -- description of the violation
        # @rbs location: Herb::Location -- location of the violation
        def add_offense(message:, location:, autofix_context: nil) #: void
          @offenses << create_offense(message:, location:, autofix_context:)
        end

        # Add an offense with autofix context for the current rule.
        # Creates an AutofixContext from the given node and current rule class,
        # then delegates to add_offense.
        #
        # @rbs message: String -- description of the violation
        # @rbs location: Herb::Location -- location of the violation
        # @rbs node: Herb::AST::Node -- the offending AST node (direct reference for autofix)
        def add_offense_with_autofix(message:, location:, node:) #: void
          context = AutofixContext.new(node:, rule_class: self.class)
          add_offense(message:, location:, autofix_context: context)
        end

        # Apply autofix to the given node in the AST.
        # Override in autofixable rules to perform AST mutation.
        # Returns true if the fix was applied, false otherwise.
        #
        # @rbs _node: untyped -- the offending AST node (type varies by rule)
        # @rbs _parse_result: Herb::ParseResult -- the parse result from the lint phase
        def autofix(_node, _parse_result) #: bool
          false
        end

        # Create an offense for a rule violation.
        #
        # @rbs message: String -- description of the violation
        # @rbs location: Herb::Location -- location of the violation
        # @rbs autofix_context: AutofixContext? -- optional autofix context for autofixable offenses
        def create_offense(message:, location:, autofix_context: nil) #: Offense
          Offense.new(rule_name: self.class.rule_name, message:, severity:, location:, autofix_context:)
        end
      end
    end
  end
end
