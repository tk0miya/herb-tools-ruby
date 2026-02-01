# frozen_string_literal: true

module Herb
  module Printer
    # Error raised when attempting to print an AST that contains parse errors.
    class PrintError < StandardError; end
  end
end
