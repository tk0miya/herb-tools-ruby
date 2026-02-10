# frozen_string_literal: true

require "json-schema"

module Herb
  module Config
    # Validates configuration hash against schema
    class Validator
      # Path to JSON Schema file
      SCHEMA_PATH = File.expand_path("schema.json", __dir__ || ".") #: String

      # @rbs config: Hash[String, untyped] -- configuration hash to validate
      def initialize(config) #: void
        @config = config
      end

      # Check if configuration is valid
      def valid? #: bool
        errors.empty?
      end

      # Validate configuration and raise error if invalid
      def validate! #: void
        return if valid?

        raise ValidationError, errors
      end

      # Return list of validation errors
      def errors #: Array[String]
        validate_config unless @errors
        @errors
      end

      private

      attr_reader :config #: Hash[String, untyped]

      # @rbs @errors: Array[String]
      def validate_config #: void
        return if @errors

        # JSON Schema validation with detailed error objects
        schema_errors = JSON::Validator.fully_validate(load_schema, config, errors_as_objects: true)
        @errors = schema_errors.map { format_schema_error_object(_1) }
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
    end
  end
end
