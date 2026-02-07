# frozen_string_literal: true

module Herb
  module Config
    # Base error class for configuration-related errors
    class Error < StandardError; end

    # Custom error raised when configuration validation fails
    class ValidationError < Error
      # @rbs errors: Array[String] -- validation error messages
      def initialize(errors) #: void
        @errors = errors
        super("Configuration validation failed:\n  - #{errors.join("\n  - ")}")
      end

      attr_reader :errors #: Array[String]
    end
  end
end
