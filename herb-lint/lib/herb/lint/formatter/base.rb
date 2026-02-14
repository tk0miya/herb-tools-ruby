# frozen_string_literal: true

module Herb
  module Lint
    module Formatter
      # Base class for all formatters.
      #
      # Formatters are responsible for outputting linting results in different formats.
      # All formatters must implement the #report method.
      class Base
        attr_reader :io #: IO

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          @io = io
        end

        # Reports the aggregated linting result.
        #
        # This method must be implemented by subclasses.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          raise NotImplementedError, "#{self.class}#report must be implemented"
        end
      end
    end
  end
end
