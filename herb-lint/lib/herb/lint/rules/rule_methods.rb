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
          base.attr_reader :options #: Hash[Symbol, untyped]?
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
        end

        # @rbs severity: String?
        # @rbs options: Hash[Symbol, untyped]?
        def initialize(severity: nil, options: nil) #: void
          @severity = severity || self.class.default_severity
          @options = options
          super() if defined?(super)
        end

        # Check the document for rule violations.
        #
        # @rbs document: Herb::ParseResult -- parsed document to check
        # @rbs context: Context -- linting context with file information
        def check(document, context) #: Array[Offense]
          raise NotImplementedError, "#{self.class.name} must implement #check"
        end

        # Create an offense for a rule violation.
        #
        # @rbs context: Context -- linting context (reserved for future use)
        # @rbs message: String -- description of the violation
        # @rbs location: Herb::Location -- location of the violation
        def create_offense(context:, message:, location:) #: Offense # rubocop:disable Lint/UnusedMethodArgument
          Offense.new(
            rule_name: self.class.rule_name,
            message: message,
            severity: severity,
            location: location
          )
        end
      end
    end
  end
end
