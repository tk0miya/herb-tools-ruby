# frozen_string_literal: true

require "herb"

require_relative "rewriter/ast_rewriter"
require_relative "rewriter/built_ins/index"
require_relative "rewriter/version"

module Herb
  module Rewriter
    class Error < StandardError; end
  end
end
