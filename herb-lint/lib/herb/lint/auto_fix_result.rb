# frozen_string_literal: true

module Herb
  module Lint
    # Result of applying automatic fixes to lint offenses
    #
    # Contains the corrected source code and tracks which offenses were
    # successfully fixed versus those that remain unfixed.
    AutoFixResult = Data.define(
      :source,  #: String
      :fixed,   #: Array[Offense]
      :unfixed  #: Array[Offense]
    )

    # :nodoc:
    class AutoFixResult
      def fixed_count = fixed.size #: Integer
      def unfixed_count = unfixed.size #: Integer
    end
  end
end
