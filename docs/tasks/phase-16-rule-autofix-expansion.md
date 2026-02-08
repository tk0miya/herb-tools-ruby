# Phase 16: Rule Autofix Expansion

This phase implements autofix methods for all existing fixable rules.

**Prerequisites:** Phase 15 (Tasks 15.1-15.6) — Autofix infrastructure must be complete

**Design Reference:** [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

## Overview

This phase expands autofix support across all rule categories:

- **Part A**: Complete autofix infrastructure (Task 16.1)
- **Part B**: ERB rule autofix (12 implemented: 6 fixable + 6 not fixable)
- **Part C**: HTML rule autofix (31 implemented: 7 fixable + 24 not fixable)
- **Part D**: Herb comment directive rules (5 implemented, detection-only)
- **Part E**: SVG rule autofix (1 implemented: 1 fixable)
- **Part F**: Parser rules (1 implemented, detection-only)

## Status Legend

- ✅ Implemented with autofix
- 🔨 Implemented, needs autofix
- ✔️ Implemented, not fixable (no autofix needed)

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
| `erb/comment-syntax` | ✅ | Yes | 16.2 |
| `erb/no-case-node-children` | ✔️ | No | - |
| `erb/no-empty-tags` | ✅ | Yes | 16.3 |
| `erb/no-extra-newline` | ✔️ | No | - |
| `erb/no-extra-whitespace-inside-tags` | ✅ | Yes | 16.4 |
| `erb/no-output-control-flow` | ✔️ | No | - |
| `erb/no-silent-tag-in-attribute-name` | ✔️ | No | - |
| `erb/prefer-image-tag-helper` | ✔️ | No | - |
| `erb/require-trailing-newline` | ✅ | Yes | 16.7 |
| `erb/require-whitespace-inside-tags` | ✅ | Yes | 16.5 |
| `erb/right-trim` | ✅ | Yes | 16.6 |
| `erb/strict-locals-required` | ✔️ | No | - |

### Task 16.2: ErbCommentSyntax Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb_comment_syntax.rb`

- [x] Add `def self.safe_autofixable? = true`
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

- [x] Add `def self.safe_autofixable? = true`
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

- [x] Add `def self.safe_autofixable? = true`
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

- [x] Add `def self.safe_autofixable? = true`
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

- [x] Add `def self.safe_autofixable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Add right trim to ERB tags
- [x] Add autofix tests

**Example:**

```erb
# Before
<% if true %>

# After
<% if true -%>
```

### Task 16.7: ErbRequireTrailingNewline Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/require_trailing_newline.rb`

- [x] Add `def self.safe_autofixable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Add trailing newline at end of file
  - [x] Remove extra trailing newlines
- [x] Add autofix tests

**Example:**

```erb
# Before (no trailing newline)
<div>content</div>
# After (trailing newline added)
<div>content</div>

# Before (multiple trailing newlines)
<div>content</div>\n\n
# After (only one trailing newline)
<div>content</div>
```

---

## Part C: HTML Rules

### Implemented Rules with Autofix Needed

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `html/attribute-double-quotes` | ✅ | Yes | 16.8 |
| `html/attribute-equals-spacing` | ✅ | Yes | 16.9 |
| `html/attribute-values-require-quotes` | 🔨 | Yes | 16.10 |
| `html/boolean-attributes-no-value` | 🔨 | Yes | 16.11 |
| `html/no-self-closing` | 🔨 | Yes | 16.12 |
| `html/no-space-in-tag` | 🔨 | Yes | 16.13 |
| `html/tag-name-lowercase` | 🔨 | Yes | 16.14 |

### Implemented Rules (Not Fixable)

| Rule | Status | Fixable |
|------|--------|---------|
| `html/anchor-require-href` | ✔️ | No |
| `html/aria-attribute-must-be-valid` | ✔️ | No |
| `html/aria-label-is-well-formatted` | ✔️ | No |
| `html/aria-level-must-be-valid` | ✔️ | No |
| `html/aria-role-heading-requires-level` | ✔️ | No |
| `html/aria-role-must-be-valid` | ✔️ | No |
| `html/avoid-both-disabled-and-aria-disabled` | ✔️ | No |
| `html/body-only-elements` | ✔️ | No |
| `html/head-only-elements` | ✔️ | No |
| `html/iframe-has-title` | ✔️ | No |
| `html/img-require-alt` | ✔️ | No |
| `html/input-require-autocomplete` | ✔️ | No |
| `html/navigation-has-label` | ✔️ | No |
| `html/no-aria-hidden-on-focusable` | ✔️ | No |
| `html/no-block-inside-inline` | ✔️ | No |
| `html/no-duplicate-attributes` | ✔️ | No |
| `html/no-duplicate-ids` | ✔️ | No |
| `html/no-duplicate-meta-names` | ✔️ | No |
| `html/no-empty-attributes` | ✔️ | No |
| `html/no-empty-headings` | ✔️ | No |
| `html/no-nested-links` | ✔️ | No |
| `html/no-positive-tab-index` | ✔️ | No |
| `html/no-title-attribute` | ✔️ | No |
| `html/no-underscores-in-attribute-names` | ✔️ | No |

### Task 16.8: HtmlAttributeDoubleQuotes Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_double_quotes.rb`

- [x] Add `def self.safe_autofixable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Add double quotes to unquoted attribute values
- [x] Add autofix tests

### Task 16.9: HtmlAttributeEqualsSpacing Autofix

**Status:** Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_equals_spacing.rb`

- [x] Add `def self.safe_autofixable? = true`
- [x] Change `add_offense` to `add_offense_with_autofix`
- [x] Implement `autofix(node, parse_result)` method
  - [x] Remove spaces around `=` in attributes
- [x] Add autofix tests

### Task 16.10: HtmlAttributeValuesRequireQuotes Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_attribute_values_require_quotes.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Add quotes around unquoted attribute values
- [ ] Add autofix tests

### Task 16.11: HtmlBooleanAttributesNoValue Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_boolean_attributes_no_value.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove value from boolean attributes
- [ ] Add autofix tests

### Task 16.12: HtmlNoSelfClosing Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_no_self_closing.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert self-closing tags to proper form
- [ ] Add autofix tests

### Task 16.13: HtmlNoSpaceInTag Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_no_space_in_tag.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Remove space after `<` in tag names
- [ ] Add autofix tests

### Task 16.14: HtmlTagNameLowercase Autofix

**Location:** `herb-lint/lib/herb/lint/rules/html_tag_name_lowercase.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Convert tag name to lowercase
- [ ] Add autofix tests

---

## Part D: Herb Comment Directive Rules

All herb comment directive rules are detection-only (not fixable):

| Rule | Status | Fixable |
|------|--------|---------|
| `herb-disable-comment/malformed` | ✔️ | No |
| `herb-disable-comment/missing-rules` | ✔️ | No |
| `herb-disable-comment/no-duplicate-rules` | ✔️ | No |
| `herb-disable-comment/no-redundant-all` | ✔️ | No |
| `herb-disable-comment/valid-rule-name` | ✔️ | No |

These rules validate herb directive comments and are not autofixable by design.

---

## Part E: SVG Rules

### Implemented Rules

| Rule | Status | Fixable | Task |
|------|--------|---------|------|
| `svg/tag-name-capitalization` | 🔨 | Yes | 16.15 |

### Task 16.15: SvgTagNameCapitalization Autofix

**Location:** `herb-lint/lib/herb/lint/rules/svg/tag_name_capitalization.rb`

- [ ] Add `def self.safe_autofixable? = true`
- [ ] Change `add_offense` to `add_offense_with_autofix`
- [ ] Implement `autofix(node, parse_result)` method
  - [ ] Fix SVG tag name capitalization (e.g., `clippath` → `clipPath`)
- [ ] Add autofix tests

---

## Part F: Parser Rules

Parser error rules are detection-only (not fixable):

| Rule | Status | Fixable |
|------|--------|---------|
| `parser/no-errors` | ✔️ | No |

Parse errors cannot be automatically corrected.

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
| B | 16.2-16.7 | ERB rules autofix (6 fixable rules) |
| C | 16.8-16.14 | HTML rules autofix (7 fixable rules) |
| D | - | Herb directive rules (detection-only, 5 rules) |
| E | 16.15 | SVG rules autofix (1 fixable rule) |
| F | - | Parser rules (detection-only, 1 rule) |

**Total: 15 tasks** (covering all 50 implemented rules: 14 fixable + 36 not fixable)

## Task Priorities

### High Priority (Core Fixable Rules)

- 16.1: AutofixHelpers ✅
- 16.3: ErbNoEmptyTags ✅
- 16.4: ErbNoExtraWhitespaceInsideTags ✅
- 16.5: ErbRequireWhitespaceInsideTags ✅
- 16.8: HtmlAttributeDoubleQuotes
- 16.10: HtmlAttributeValuesRequireQuotes
- 16.14: HtmlTagNameLowercase

### Medium Priority (Style Rules)

- 16.2: ErbCommentSyntax ✅
- 16.6: ErbRightTrim ✅
- 16.7: ErbRequireTrailingNewline ✅
- 16.9: HtmlAttributeEqualsSpacing
- 16.11: HtmlBooleanAttributesNoValue
- 16.13: HtmlNoSpaceInTag

### Lower Priority

- 16.12: HtmlNoSelfClosing
- 16.15: SvgTagNameCapitalization

## Related Documents

- [Phase 15: Autofix](./phase-15-autofix.md) — Infrastructure tasks (15.1-15.7)
- [Autofix Design](../design/herb-lint-autofix-design.md) — Detailed design
- [herb-lint Specification](../requirements/herb-lint.md) — Full rule list
