# frozen_string_literal: true

module Herb
  module Lint
    module Reporter
      # Base class for all reporters.
      class Base
        attr_reader :io #: IO

        # @rbs io: IO
        def initialize(io: $stdout) #: void
          @io = io
        end

        # Reports the aggregated linting result.
        # Subclasses must implement this method.
        #
        # @rbs aggregated_result: AggregatedResult
        def report(aggregated_result) #: void
          raise NotImplementedError, "#{self.class}#report must be implemented"
        end
      end
    end
  end
end
