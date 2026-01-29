# frozen_string_literal: true

require "herb"

# Require files in ASCII order
require_relative "lint/aggregated_result"
require_relative "lint/cli"
require_relative "lint/context"
require_relative "lint/lint_result"
require_relative "lint/linter"
require_relative "lint/offense"
require_relative "lint/reporter/simple_reporter"
require_relative "lint/rule_registry"
require_relative "lint/runner"
require_relative "lint/rules/base"
require_relative "lint/rules/visitor_rule"
require_relative "lint/rules/a11y/alt_text"
require_relative "lint/rules/html/attribute_quotes"
require_relative "lint/rules/html/no_duplicate_attributes"
require_relative "lint/rules/html/no_duplicate_id"
require_relative "lint/version"

module Herb
  module Lint
    class Error < StandardError; end
  end
end
