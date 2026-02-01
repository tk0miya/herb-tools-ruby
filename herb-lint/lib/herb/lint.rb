# frozen_string_literal: true

require "herb"

# Require files in ASCII order
require_relative "lint/aggregated_result"
require_relative "lint/cli"
require_relative "lint/context"
require_relative "lint/directive_parser"
require_relative "lint/lint_result"
require_relative "lint/linter"
require_relative "lint/offense"
require_relative "lint/reporter/json_reporter"
require_relative "lint/reporter/simple_reporter"
require_relative "lint/rule_registry"
require_relative "lint/runner"
require_relative "lint/unnecessary_directive_detector"
require_relative "lint/rules/base"
require_relative "lint/rules/directive_rule"
require_relative "lint/rules/node_helpers"
require_relative "lint/rules/visitor_rule"
require_relative "lint/rules/erb_comment_syntax"
require_relative "lint/rules/herb_disable_comment_malformed"
require_relative "lint/rules/herb_disable_comment_missing_rules"
require_relative "lint/rules/herb_disable_comment_no_duplicate_rules"
require_relative "lint/rules/herb_disable_comment_no_redundant_all"
require_relative "lint/rules/herb_disable_comment_valid_rule_name"
require_relative "lint/rules/html_anchor_require_href"
require_relative "lint/rules/html_aria_attribute_must_be_valid"
require_relative "lint/rules/html_attribute_double_quotes"
require_relative "lint/rules/html_attribute_equals_spacing"
require_relative "lint/rules/html_attribute_values_require_quotes"
require_relative "lint/rules/html_boolean_attributes_no_value"
require_relative "lint/rules/html_iframe_has_title"
require_relative "lint/rules/html_img_require_alt"
require_relative "lint/rules/html_no_duplicate_attributes"
require_relative "lint/rules/html_no_duplicate_ids"
require_relative "lint/rules/html_no_duplicate_meta_names"
require_relative "lint/rules/html_no_empty_attributes"
require_relative "lint/rules/html_no_nested_links"
require_relative "lint/rules/html_no_title_attribute"
require_relative "lint/rules/html_no_underscores_in_attribute_names"
require_relative "lint/rules/html_no_positive_tab_index"
require_relative "lint/rules/html_no_self_closing"
require_relative "lint/rules/html_tag_name_lowercase"
require_relative "lint/version"

module Herb
  module Lint
    class Error < StandardError; end
  end
end
