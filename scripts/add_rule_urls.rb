#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to add documentation and source URLs to rule files

require "fileutils"

# Map of rule files to their rule names (in kebab-case)
RULE_FILES = {
  "erb_comment_syntax.rb" => "erb-comment-syntax",
  "erb_no_case_node_children.rb" => "erb-no-case-node-children",
  "erb_no_empty_tags.rb" => "erb-no-empty-tags",
  "erb_no_extra_whitespace_inside_tags.rb" => "erb-no-extra-whitespace-inside-tags",
  "erb_no_output_control_flow.rb" => "erb-no-output-control-flow",
  "erb_prefer_image_tag_helper.rb" => "erb-prefer-image-tag-helper",
  "erb_require_whitespace_inside_tags.rb" => "erb-require-whitespace-inside-tags",
  "erb_right_trim.rb" => "erb-right-trim",
  "herb_disable_comment_malformed.rb" => "herb-disable-comment-malformed",
  "herb_disable_comment_missing_rules.rb" => "herb-disable-comment-missing-rules",
  "herb_disable_comment_no_duplicate_rules.rb" => "herb-disable-comment-no-duplicate-rules",
  "herb_disable_comment_no_redundant_all.rb" => "herb-disable-comment-no-redundant-all",
  "herb_disable_comment_valid_rule_name.rb" => "herb-disable-comment-valid-rule-name",
  "html_anchor_require_href.rb" => "html-anchor-require-href",
  "html_aria_attribute_must_be_valid.rb" => "html-aria-attribute-must-be-valid",
  "html_aria_label_is_well_formatted.rb" => "html-aria-label-is-well-formatted",
  "html_aria_level_must_be_valid.rb" => "html-aria-level-must-be-valid",
  "html_aria_role_heading_requires_level.rb" => "html-aria-role-heading-requires-level",
  "html_aria_role_must_be_valid.rb" => "html-aria-role-must-be-valid",
  "html_attribute_double_quotes.rb" => "html-attribute-double-quotes",
  "html_attribute_equals_spacing.rb" => "html-attribute-equals-spacing",
  "html_attribute_values_require_quotes.rb" => "html-attribute-values-require-quotes",
  "html_avoid_both_disabled_and_aria_disabled.rb" => "html-avoid-both-disabled-and-aria-disabled",
  "html_body_only_elements.rb" => "html-body-only-elements",
  "html_boolean_attributes_no_value.rb" => "html-boolean-attributes-no-value",
  "html_head_only_elements.rb" => "html-head-only-elements",
  "html_iframe_has_title.rb" => "html-iframe-has-title",
  "html_img_require_alt.rb" => "html-img-require-alt",
  "html_input_require_autocomplete.rb" => "html-input-require-autocomplete",
  "html_navigation_has_label.rb" => "html-navigation-has-label",
  "html_no_aria_hidden_on_focusable.rb" => "html-no-aria-hidden-on-focusable",
  "html_no_block_inside_inline.rb" => "html-no-block-inside-inline",
  "html_no_duplicate_attributes.rb" => "html-no-duplicate-attributes",
  "html_no_duplicate_ids.rb" => "html-no-duplicate-ids",
  "html_no_duplicate_meta_names.rb" => "html-no-duplicate-meta-names",
  "html_no_empty_attributes.rb" => "html-no-empty-attributes",
  "html_no_empty_headings.rb" => "html-no-empty-headings",
  "html_no_nested_links.rb" => "html-no-nested-links",
  "html_no_positive_tab_index.rb" => "html-no-positive-tab-index",
  "html_no_self_closing.rb" => "html-no-self-closing",
  "html_no_space_in_tag.rb" => "html-no-space-in-tag",
  "html_no_title_attribute.rb" => "html-no-title-attribute",
  "html_no_underscores_in_attribute_names.rb" => "html-no-underscores-in-attribute-names",
  "html_tag_name_lowercase.rb" => "html-tag-name-lowercase"
}

RULES_DIR = File.expand_path("../herb-lint/lib/herb/lint/rules", __dir__)

def generate_url_comment(rule_name)
  doc_url = "https://herb-tools.dev/linter/rules/#{rule_name}"
  source_url = "https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/#{rule_name}.ts"

  <<~COMMENT.chomp
    #
    # @see #{doc_url} Documentation
    # @see #{source_url} Source
  COMMENT
end

def has_url_comment?(content)
  content.include?("@see https://herb-tools.dev") ||
    content.include?("@see https://github.com/marcoroth/herb")
end

def add_url_to_file(file_path, rule_name)
  content = File.read(file_path)

  # Skip if URLs already exist
  if has_url_comment?(content)
    puts "  Skipping (already has URLs)"
    return false
  end

  url_comment = generate_url_comment(rule_name)

  # Find the position to insert: right before the class definition
  # Pattern: Look for "class RuleName < Base" or "class RuleName < VisitorRule"
  class_pattern = /^(\s*)(class \w+ < (?:VisitorRule|DirectiveRule|Base))/

  if content =~ class_pattern
    indent = $1
    # Add the URL comment before the class definition
    new_content = content.sub(class_pattern) do
      "#{url_comment}\n#{indent}#{$2}"
    end

    File.write(file_path, new_content)
    puts "  ✓ Added URLs"
    true
  else
    puts "  ✗ Could not find class definition"
    false
  end
end

# Main execution
puts "Adding documentation and source URLs to rule files...\n\n"

success_count = 0
skip_count = 0
error_count = 0

RULE_FILES.each do |filename, rule_name|
  file_path = File.join(RULES_DIR, filename)

  unless File.exist?(file_path)
    puts "#{filename}: File not found"
    error_count += 1
    next
  end

  print "#{filename}: "

  result = add_url_to_file(file_path, rule_name)
  if result
    success_count += 1
  elsif has_url_comment?(File.read(file_path))
    skip_count += 1
  else
    error_count += 1
  end
end

puts "\n" + "=" * 60
puts "Summary:"
puts "  ✓ Added: #{success_count}"
puts "  - Skipped: #{skip_count}"
puts "  ✗ Errors: #{error_count}"
puts "  Total: #{RULE_FILES.size}"
puts "=" * 60
