# Phase 16: Rule Autofix Expansion

This phase implements autofix methods for all existing rules and implements remaining rules from the specification with autofix support.

**Prerequisites:** Phase 15 (Tasks 15.1-15.6) — Autofix infrastructure must be complete

**Design Reference:** [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

## Overview

This phase expands autofix support across all rule categories:

- **Part A**: Complete autofix infrastructure (Task 15.7)
- **Part B**: ERB rule autofix (8 implemented + 5 unimplemented)
- **Part C**: HTML rule autofix (43 implemented + missing from spec)
- **Part D**: Accessibility rule autofix (included in HTML rules + standalone a11y rules)

## Status Legend

- ✅ Implemented with autofix
- 🔨 Implemented, needs autofix
- 📝 Not implemented yet

---

## Part A: Complete Autofix Infrastructure

### Task 16.1: Autofix Utility Helpers

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/autofix_helpers.rb`

- [x] Implement `AutofixHelpers` module
  - [x] `parent_array_for(parent, node)` — find mutable array containing node
  - [x] `find_parent(parse_result, node)` — wrapper around `NodeLocator.find_parent`
- [x] Include in `VisitorRule` base class
- [x] Add unit tests
- [x] Generate RBS types

**Verification:**

```bash
cd herb-lint && ./bin/rspec spec/herb/lint/autofix_helpers_spec.rb
cd herb-lint && ./bin/steep check
```

---

## Part B: ERB Rules

### Implemented Rules

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `erb/comment-syntax` | 🔨 | Yes | 16.2 |
| `erb/no-case-node-children` | 🔨 | No | - |
| `erb/no-empty-tags` | 🔨 | Yes | 16.3 |
| `erb/no-extra-whitespace-inside-tags` | 🔨 | Yes | 16.4 |
| `erb/no-output-control-flow` | 🔨 | No | - |
| `erb/prefer-image-tag-helper` | 🔨 | No | - |
| `erb/require-whitespace-inside-tags` | 🔨 | Yes | 16.5 |
| `erb/right-trim` | 🔨 | Yes | 16.6 |

### Unimplemented Rules (from specification)

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `erb/no-trailing-whitespace` | 📝 | Yes | 16.7 |
| `erb/indent` | 📝 | Yes | 16.8 |
| `erb/no-space-before-close` | 📝 | Yes | 16.9 |
| `erb/space-after-open` | 📝 | Yes | 16.10 |
| `erb/consistent-quotes` | 📝 | Yes | 16.11 |

### Task 16.2: ErbCommentSyntax Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb_comment_syntax.rb`

- [x] Add `def self.safe_autocorrectable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix` (pass `node:` parameter)
- [x] Implement `autofix(node, parse_result)` method
  - [x] Convert statement tag with Ruby comment to ERB comment tag
- [x] Add autofix tests

**Example:**

```erb
# Before
<!-- comment -->

# After
<%# comment %>
```

### Task 16.3: ErbNoEmptyTags Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb_no_empty_tags.rb`

- [x] Add `def self.autocorrectable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Remove empty ERB tags
- [x] Add autofix tests
- [x] Add `remove_node` helper to `AutofixHelpers`

**Example:**

```erb
# Before
<% %>

# After
(removed)
```

### Task 16.4: ErbNoExtraWhitespaceInsideTags Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb_no_extra_whitespace_inside_tags.rb`

- [x] Add `def self.autocorrectable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Remove extra whitespace inside ERB tags
- [x] Add autofix tests

**Example:**

```erb
# Before
<%  foo  %>

# After
<% foo %>
```

### Task 16.5: ErbRequireWhitespaceInsideTags Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb_require_whitespace_inside_tags.rb`

- [x] Add `def self.autocorrectable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Add required whitespace inside ERB tags
- [x] Add autofix tests

**Example:**

```erb
# Before
<%foo%>

# After
<% foo %>
```

### Task 16.6: ErbRightTrim Autofix

**Location:** `herb-lint/lib/herb/lint/rules/erb_right_trim.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add right trim to ERB tags
- [ ] Add autofix tests

**Example:**

```erb
# Before
<% if true %>

# After
<% if true -%>
```

### Task 16.7: Implement erb/no-trailing-whitespace

**Location:** `herb-lint/lib/herb/lint/rules/erb_no_trailing_whitespace.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic
- [ ] Implement `autofix(node, parse_result)` method
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

**Description:** Remove trailing whitespace in ERB output tags.

### Task 16.8: Implement erb/indent

**Location:** `herb-lint/lib/herb/lint/rules/erb_indent.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic
- [ ] Implement `autofix(node, parse_result)` method
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

**Description:** Enforce consistent indentation in ERB blocks.

### Task 16.9: Implement erb/no-space-before-close

**Location:** `herb-lint/lib/herb/lint/rules/erb_no_space_before_close.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic
- [ ] Implement `autofix(node, parse_result)` method
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

**Description:** Remove space before closing `%>`.

### Task 16.10: Implement erb/space-after-open

**Location:** `herb-lint/lib/herb/lint/rules/erb_space_after_open.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic
- [ ] Implement `autofix(node, parse_result)` method
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

**Description:** Require space after opening `<%`.

### Task 16.11: Implement erb/consistent-quotes

**Location:** `herb-lint/lib/herb/lint/rules/erb_consistent_quotes.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic
- [ ] Implement `autofix(node, parse_result)` method
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

**Description:** Enforce consistent quote style in ERB code.

---

## Part C: HTML Rules

### Implemented Rules with Autofix Needed

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `html/attribute-double-quotes` | 🔨 | Yes | 16.12 |
| `html/attribute-equals-spacing` | 🔨 | Yes | 16.13 |
| `html/attribute-values-require-quotes` | 🔨 | Yes | 16.14 |
| `html/boolean-attributes-no-value` | 🔨 | Yes | 16.15 |
| `html/no-self-closing` | 🔨 | Yes | 16.16 |
| `html/no-space-in-tag` | 🔨 | Yes | 16.17 |
| `html/tag-name-lowercase` | 🔨 | Yes | 16.18 |

### Implemented Rules (Not Fixable)

| Rule | Status | Fixable |
|------|--------|---------|
| `html/anchor-require-href` | 🔨 | No |
| `html/aria-attribute-must-be-valid` | 🔨 | No |
| `html/aria-label-is-well-formatted` | 🔨 | No |
| `html/aria-level-must-be-valid` | 🔨 | No |
| `html/aria-role-heading-requires-level` | 🔨 | No |
| `html/aria-role-must-be-valid` | 🔨 | No |
| `html/avoid-both-disabled-and-aria-disabled` | 🔨 | No |
| `html/body-only-elements` | 🔨 | No |
| `html/head-only-elements` | 🔨 | No |
| `html/iframe-has-title` | 🔨 | No |
| `html/img-require-alt` | 🔨 | No |
| `html/input-require-autocomplete` | 🔨 | No |
| `html/navigation-has-label` | 🔨 | No |
| `html/no-aria-hidden-on-focusable` | 🔨 | No |
| `html/no-block-inside-inline` | 🔨 | No |
| `html/no-duplicate-attributes` | 🔨 | No |
| `html/no-duplicate-ids` | 🔨 | No |
| `html/no-duplicate-meta-names` | 🔨 | No |
| `html/no-empty-attributes` | 🔨 | No |
| `html/no-empty-headings` | 🔨 | No |
| `html/no-nested-links` | 🔨 | No |
| `html/no-positive-tab-index` | 🔨 | No |
| `html/no-title-attribute` | 🔨 | No |
| `html/no-underscores-in-attribute-names` | 🔨 | No |

### Unimplemented Rules (from specification)

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `html/no-target-blank` | 📝 | Yes | 16.19 |
| `html/button-type` | 📝 | Yes | 16.20 |
| `html/script-type` | 📝 | Yes | 16.21 |
| `html/style-type` | 📝 | Yes | 16.22 |
| `html/no-redundant-role` | 📝 | Yes | 16.23 |
| `html/lowercase-attributes` | 📝 | Yes | 16.24 |
| `html/void-element-style` | 📝 | Yes | 16.25 |

### Task 16.12: HtmlAttributeDoubleQuotes Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_attribute_double_quotes.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert single quotes to double quotes
- [ ] Add autofix tests

### Task 16.13: HtmlAttributeEqualsSpacing Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_attribute_equals_spacing.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove spaces around `=` in attributes
- [ ] Add autofix tests

### Task 16.14: HtmlAttributeValuesRequireQuotes Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_attribute_values_require_quotes.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add quotes around unquoted attribute values
- [ ] Add autofix tests

### Task 16.15: HtmlBooleanAttributesNoValue Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_boolean_attributes_no_value.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove value from boolean attributes
- [ ] Add autofix tests

### Task 16.16: HtmlNoSelfClosing Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_no_self_closing.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert self-closing tags to proper form
- [ ] Add autofix tests

### Task 16.17: HtmlNoSpaceInTag Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_no_space_in_tag.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove space after `<` in tag names
- [ ] Add autofix tests

### Task 16.18: HtmlTagNameLowercase Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_tag_name_lowercase.rb`

- [ ] Add `def self.autocorrectable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert tag name to lowercase
- [ ] Add autofix tests

### Task 16.19: Implement html/no-target-blank

**Location:** `herb-lint/lib/herb/lint/rules/html_no_target_blank.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (warn about `target="_blank"` without `rel`)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add `rel="noopener noreferrer"` to links with `target="_blank"`
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.20: Implement html/button-type

**Location:** `herb-lint/lib/herb/lint/rules/html_button_type.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (require `type` attribute on buttons)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add `type="button"` to buttons without type
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.21: Implement html/script-type

**Location:** `herb-lint/lib/herb/lint/rules/html_script_type.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (omit `type` for JavaScript)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove `type="text/javascript"` from script tags
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.22: Implement html/style-type

**Location:** `herb-lint/lib/herb/lint/rules/html_style_type.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (omit `type` for CSS)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove `type="text/css"` from style tags
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.23: Implement html/no-redundant-role

**Location:** `herb-lint/lib/herb/lint/rules/html_no_redundant_role.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (avoid redundant roles)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove redundant role attributes
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.24: Implement html/lowercase-attributes

**Location:** `herb-lint/lib/herb/lint/rules/html_lowercase_attributes.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (enforce lowercase attribute names)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert attribute names to lowercase
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

### Task 16.25: Implement html/void-element-style

**Location:** `herb-lint/lib/herb/lint/rules/html_void_element_style.rb`

- [ ] Implement rule class
- [ ] Add `def self.autocorrectable? = true`
- [ ] Implement detection logic (consistent self-closing style for void elements)
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Apply consistent void element style
- [ ] Register in `RuleRegistry`
- [ ] Add to `herb-lint/lib/herb/lint.rb`
- [ ] Add detection tests
- [ ] Add autofix tests

---

## Part D: Herb Comment Directive Rules

All herb comment directive rules are detection-only (not fixable):

| Rule | Status | Fixable |
|------|--------|---------|
| `herb-disable-comment/malformed` | 🔨 | No |
| `herb-disable-comment/missing-rules` | 🔨 | No |
| `herb-disable-comment/no-duplicate-rules` | 🔨 | No |
| `herb-disable-comment/no-redundant-all` | 🔨 | No |
| `herb-disable-comment/valid-rule-name` | 🔨 | No |

These rules validate herb directive comments and are not autofixable by design.

---

## Verification

### Unit Tests

```bash
# Test each rule's autofix
cd herb-lint && ./bin/rspec spec/herb/lint/rules/
```

### Integration Tests

```bash
# Test autofix end-to-end
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb --tag autofix
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb --tag autofix
```

### Type Check

```bash
cd herb-lint && ./bin/steep check
```

### Manual Testing

```erb
<%# test.html.erb %>
<DIV class='foo'>
  <IMG src="test.png">
  <%foo%>
</DIV>
```

```bash
herb-lint --fix test.html.erb
cat test.html.erb
# Expected:
# <div class="foo">
#   <img src="test.png">
#   <% foo %>
# </div>
```

---

## Summary

| Part | Tasks | Description |
|------|-------|-------------|
| A | 16.1 | Complete autofix infrastructure |
| B | 16.2-16.11 | ERB rules autofix (5 existing + 5 new) |
| C | 16.12-16.25 | HTML rules autofix (7 existing + 7 new) |
| D | - | Herb directive rules (detection-only) |

**Total: 25 tasks**

## Task Priorities

### High Priority (Core Fixable Rules)

- 16.1: AutofixHelpers
- 16.3: ErbNoEmptyTags
- 16.4: ErbNoExtraWhitespaceInsideTags
- 16.5: ErbRequireWhitespaceInsideTags
- 16.12: HtmlAttributeDoubleQuotes
- 16.14: HtmlAttributeValuesRequireQuotes
- 16.18: HtmlTagNameLowercase

### Medium Priority (Style Rules)

- 16.2: ErbCommentSyntax
- 16.6: ErbRightTrim
- 16.13: HtmlAttributeEqualsSpacing
- 16.15: HtmlBooleanAttributesNoValue
- 16.17: HtmlNoSpaceInTag

### Lower Priority (New Rules)

- 16.7-16.11: New ERB rules
- 16.19-16.25: New HTML rules

## Related Documents

- [Phase 15: Autofix](./phase-15-autofix.md) — Infrastructure tasks (15.1-15.7)
- [Autofix Design](../design/herb-lint-autofix-design.md) — Detailed design
- [herb-lint Specification](../requirements/herb-lint.md) — Full rule list
