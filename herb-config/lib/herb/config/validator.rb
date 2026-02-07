# frozen_string_literal: true

require "json-schema"

module Herb
  module Config
    # Validates configuration hash against schema
    class Validator
      # Path to JSON Schema file
      SCHEMA_PATH = File.expand_path("schema.json", __dir__ || ".") #: String

      # @rbs config: Hash[String, untyped] -- configuration hash to validate
      # @rbs known_rules: Array[String] -- list of known rule names for validation
      def initialize(config, known_rules: []) #: void
        @config = config
        @known_rules = known_rules
      end

      # Check if configuration is valid
      def valid? #: bool
        actual_errors.empty?
      end

      # Validate configuration and raise error if invalid
      # @rbs return: void
      def validate! #: void
        return if valid?

        raise ValidationError, actual_errors
      end

      # Return list of validation errors
      def errors #: Array[String]
        validate_config unless @errors
        @errors
      end

      private

      attr_reader :config #: Hash[String, untyped]
      attr_reader :known_rules #: Array[String]

      # @rbs @errors: Array[String]

      def validate_config #: void
        return if @errors

        @errors = []

        # JSON Schema validation with detailed error objects
        schema_errors = JSON::Validator.fully_validate(load_schema, config, errors_as_objects: true)
        @errors.concat(schema_errors.map { |error| format_schema_error_object(error) })

        # Custom validations (not expressible in JSON Schema)
        validate_known_rules
      end

      # Load JSON Schema from file
      def load_schema #: Hash[String, untyped]
        JSON.parse(File.read(SCHEMA_PATH))
      end

      # Format JSON Schema error object to readable message
      # @rbs error: Hash[Symbol, untyped]
      def format_schema_error_object(error) #: String
        error.fetch(:message, "")
             .gsub(%r{#/}, "")  # Remove #/ prefix
             .tr("/", ".")      # Convert / to .
             .gsub(/ in schema [a-f0-9-]+/, "") # Remove schema ID suffix
      end

      # Validate rule names against known_rules list
      def validate_known_rules #: void
        return if known_rules.empty?

        linter = config["linter"]
        return unless linter.is_a?(Hash)

        rules = linter["rules"]
        return unless rules.is_a?(Hash)

        rules.each_key do |rule_name|
          next if known_rules.include?(rule_name)

          add_warning("unknown rule '#{rule_name}' (this is a warning, not an error)")
        end
      end

      # @rbs message: String
      def add_error(message) #: void
        @errors << message
      end

      # @rbs message: String
      def add_warning(message) #: void
        @errors << "Warning: #{message}"
      end

      # Return only actual errors (excluding warnings)
      def actual_errors #: Array[String]
        errors.reject { |error| error.start_with?("Warning: ") }
      end
    end
  end
end
