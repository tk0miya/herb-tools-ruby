# frozen_string_literal: true

require "herb"

# Require files in ASCII order
require_relative "lint/aggregated_result"
require_relative "lint/context"
require_relative "lint/lint_result"
require_relative "lint/offense"
require_relative "lint/rules/base"
require_relative "lint/rules/visitor_rule"
require_relative "lint/version"

module Herb
  module Lint
    class Error < StandardError; end
  end
end
