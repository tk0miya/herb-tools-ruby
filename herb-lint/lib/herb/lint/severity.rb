# frozen_string_literal: true

module Herb
  module Lint
    # Severity levels and their numeric ranks for comparison.
    # Higher rank means more severe.
    module Severity
      ERROR = "error"
      WARNING = "warning"
      INFO = "info"
      HINT = "hint"

      # Mapping of severity types to their numeric ranks.
      # Used for comparing severity levels and determining exit codes.
      RANKS = {
        ERROR => 4,
        WARNING => 3,
        INFO => 2,
        HINT => 1
      }.freeze #: Hash[String, Integer]

      # Returns the numeric rank for a given severity type.
      # Raises an error for unknown severity types.
      #
      # @rbs severity_type: String -- severity type ("error", "warning", "info", "hint")
      def self.rank(severity_type) #: Integer
        RANKS.fetch(severity_type) do
          raise ArgumentError, "Unknown severity type: #{severity_type.inspect}"
        end
      end
    end
  end
end
