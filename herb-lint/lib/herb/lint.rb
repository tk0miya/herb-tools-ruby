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
require_relative "lint/rules/node_helpers"
require_relative "lint/rules/visitor_rule"
require_relative "lint/rules/a11y/alt_text"
require_relative "lint/rules/a11y/iframe_has_title"
require_relative "lint/rules/a11y/no_access_key"
require_relative "lint/rules/a11y/no_redundant_role"
require_relative "lint/rules/erb/erb_tag_spacing"
require_relative "lint/rules/html/attribute_quotes"
require_relative "lint/rules/html/button_type"
require_relative "lint/rules/html/lowercase_attributes"
require_relative "lint/rules/html/lowercase_tags"
require_relative "lint/rules/html/no_duplicate_attributes"
require_relative "lint/rules/html/no_duplicate_id"
require_relative "lint/rules/html/no_obsolete_tags"
require_relative "lint/rules/html/no_positive_tabindex"
require_relative "lint/rules/html/no_target_blank"
require_relative "lint/rules/html/void_element_style"
require_relative "lint/version"

module Herb
  module Lint
    class Error < StandardError; end
  end
end
