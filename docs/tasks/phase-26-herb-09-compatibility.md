# Phase 26: herb gem 0.9.0 Compatibility

Address breaking changes introduced by upgrading herb gem from v0.8.9 to v0.9.0
and update existing code accordingly.

**Status**: Not Started
**Priority**: High (contains breaking changes, highest priority)
**Dependencies**: None

## Overview

herb 0.9.0 introduces several changes that directly affect the Ruby implementation:
AST field renames, `strict: true` becoming the default, accessibility rule severity
changes, and expansion of the `html-anchor-require-href` rule.

## Implementation Checklist

### Task 26.1: `HTMLElementNode#source` → `#element_source` Field Rename

In herb 0.9.0, the `source` field on `HTMLElementNode` was **renamed** to
`element_source` (breaking change).

**Audit and fix all affected gems:**
- [ ] Audit `herb-core` for any references to `HTMLElementNode#source` and fix
- [ ] Audit `herb-printer` for any references to `HTMLElementNode#source` and fix
- [ ] Audit `herb-lint` for any references to `HTMLElementNode#source` and fix
- [ ] Audit `herb-format` for any references to `HTMLElementNode#source` and fix
- [ ] Audit specs across all gems for any references to `HTMLElementNode#source` and fix
- [ ] Verify all gem test suites pass after fixes

**Verification:**
```bash
# Confirm no remaining references to the old .source field (migrated to element_source)
grep -rn "\.source\b" herb-*/lib herb-*/spec 2>/dev/null | grep -v "element_source\|source_location\|source_line\|source_file\|source_path\|source_range\|source_rule\|source_code\|context\.source\|autofix.*source\|parse_result.*source"
```

---

### Task 26.2: Adapt to `strict: true` Becoming the Default

As of herb 0.9.0, `Herb.parse` defaults to `strict: true`. This means HTML with
optional closing tags (e.g. `<p>`, `<li>`) now produces `OmittedClosingTagError`,
which may break existing tests.

**Investigation:**
- [ ] Audit all `Herb.parse` call sites in `herb-lint` (e.g. `herb-lint/lib/herb/lint/linter.rb`)
- [ ] Audit all `Herb.parse` call sites in `herb-format`
- [ ] Run all gem test suites and identify tests broken by `OmittedClosingTagError`

**Choose one approach and implement:**

Option A: Pass `strict: false` explicitly to preserve backward compatibility
```ruby
Herb.parse(source, track_whitespace: true, strict: false)
```

Option B: Accept `strict: true` as the new default and update tests to match the
new behavior (expose `strict:` as an option for callers that need to handle
templates with omitted closing tags)

- [ ] Decide on an approach and implement it
- [ ] Verify all gem test suites pass after the fix

---

### Task 26.3: Add Visitor Support for 7 New AST Node Types

herb 0.9.0 introduces the following 7 new node types. Without `visit_*` methods
for these nodes, `herb-printer` and `herb-lint` will raise `NoMethodError` when
encountering them.

| Node name | Description |
|-----------|-------------|
| `HTMLConditionalOpenTagNode` | Conditional open tag wrapped in `<% if %>` |
| `HTMLConditionalElementNode` | Entire conditional HTML element |
| `HTMLOmittedCloseTagNode` | Omitted close tag (e.g. for `<p>`) |
| `HTMLVirtualCloseTagNode` | Virtual close tag inserted internally by the parser |
| `ERBOpenTagNode` | ERB open tag node (introduced for Action View helper detection) |
| `RubyLiteralNode` | Ruby literal node |
| `RubyHTMLAttributesSplatNode` | Attribute splat node (`**attrs` style) |

**herb-printer:**
- [ ] Add `visit_*` methods for all 7 nodes in `herb-printer/lib/herb/printer/identity_printer.rb`
- [ ] Verify each node's children structure in the herb AST reference and implement
  appropriate child visitation
- [ ] Verify `herb-printer` test suite passes

**herb-lint:**
- [ ] Add default visit methods for all 7 nodes in `herb-lint/lib/herb/lint/rules/visitor_rule.rb`
  (default behavior: recursively visit children)
- [ ] Verify `herb-lint` test suite passes

**herb-core (if a Visitor base class exists):**
- [ ] Apply the same changes to any Visitor base class in `herb-core`

---

### Task 26.4: Change severity of 14 Accessibility Rules from `"error"` to `"warning"`

In TypeScript v0.9.0, the `defaultSeverity` of 14 accessibility-related rules was
changed from `"error"` to `"warning"`. Update the Ruby implementation to match.

**Rules to update (change `def self.default_severity` from `"error"` to `"warning"`):**

| Rule name | Ruby file |
|-----------|-----------|
| `html-aria-attribute-must-be-valid` | `rules/html/aria_attribute_must_be_valid.rb` |
| `html-aria-label-is-well-formatted` | `rules/html/aria_label_is_well_formatted.rb` |
| `html-aria-level-must-be-valid` | `rules/html/aria_level_must_be_valid.rb` |
| `html-aria-role-heading-requires-level` | `rules/html/aria_role_heading_requires_level.rb` |
| `html-aria-role-must-be-valid` | `rules/html/aria_role_must_be_valid.rb` |
| `html-avoid-both-disabled-and-aria-disabled` | `rules/html/avoid_both_disabled_and_aria_disabled.rb` |
| `html-iframe-has-title` | `rules/html/iframe_has_title.rb` |
| `html-img-require-alt` | `rules/html/img_require_alt.rb` |
| `html-input-require-autocomplete` | `rules/html/input_require_autocomplete.rb` |
| `html-navigation-has-label` | `rules/html/navigation_has_label.rb` |
| `html-no-aria-hidden-on-focusable` | `rules/html/no_aria_hidden_on_focusable.rb` |
| `html-no-empty-headings` | `rules/html/no_empty_headings.rb` |
| `html-no-positive-tab-index` | `rules/html/no_positive_tab_index.rb` |
| `html-no-title-attribute` | `rules/html/no_title_attribute.rb` |

**Steps:**
- [ ] Update `def self.default_severity` from `"error"` to `"warning"` in all 14 files above
- [ ] Update severity assertions in each rule's spec to expect `"warning"`
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### Task 26.5: Expand `html-anchor-require-href` Rule

The `html-anchor-require-href` rule was significantly expanded in TypeScript v0.9.0.

**Changes:**
1. Visit target changed from `visit_html_open_tag_node` to `visit_html_element_node`
2. Three new offense patterns added:
   - `href="#"` — scrolls to page top, which is inappropriate
   - `href="javascript:void(0)"` / values starting with `javascript:void` — use `<button>` instead
   - `href` value containing `url_for(nil)` (equivalent to `link_to nil`)
3. Inspect `href` on Action View helpers (e.g. `link_to`) via `ERBOpenTagNode`
4. Typo fixed in TypeScript: `AnchorRechireHrefVisitor` → `AnchorRequireHrefVisitor`
   (no equivalent in the Ruby implementation)

**Steps:**
- [ ] Compare `herb-lint/lib/herb/lint/rules/html/anchor_require_href.rb` against
  the TypeScript implementation
- [ ] Change `visit_html_open_tag_node` to `visit_html_element_node`
- [ ] Add detection for `href="#"`
- [ ] Add detection for `href="javascript:void..."` values
- [ ] Add detection for `href` values containing `url_for(nil)`
- [ ] Add logic to extract `href` from `ERBOpenTagNode` (once Task 26.3 is complete)
- [ ] Add test cases for all new offense patterns to the spec
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### Task 26.6: Per-rule `parser_options` API

In TypeScript v0.9.0, rules can declare `get parserOptions()` to request specific
parser options for their analysis (e.g. `{ action_view_helpers: true }`). The
`Linter` collects these declarations from all enabled rules and merges the options
before calling `Herb.parse`.

Without this mechanism, rules that require special parser options (such as
`html-anchor-require-href` which needs Action View helper recognition) will not
work correctly.

**TypeScript pattern:**
```typescript
// In a rule class
get parserOptions(): Partial<ParserOptions> {
  return { action_view_helpers: true }
}
```
The Linter then merges options from all active rules before parsing.

**Steps:**
- [ ] Add an optional `parser_options` class method to the rule base class
  (default returns `{}`)
- [ ] Update rules that require specific parser options to override `parser_options`
  (at minimum `html-anchor-require-href` needs `{ action_view_helpers: true }`)
- [ ] Update `Herb::Lint::Linter` to collect `parser_options` from all enabled
  rules and merge them before calling `Herb.parse`
- [ ] Verify that `html-anchor-require-href` correctly inspects Action View helper
  elements after this change
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes
