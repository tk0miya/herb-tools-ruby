# Task: Align Rule Directory Structure and Naming with TypeScript Reference

Align the Ruby lint rule directory structure and naming conventions with the TypeScript reference implementation (`@herb-tools/linter`).

## Background

The current Ruby implementation diverges from the TypeScript reference in rule directory layout, category structure, and rule naming. Since both implementations share the same `.herb.yml` configuration file format, rule names must be identical.

## Current Problems

### 1. `a11y/` category does not exist in TypeScript

TypeScript puts all rules (including accessibility rules) in a flat `rules/` directory with `html-` prefix:

```
# TypeScript
rules/
  html-img-require-alt.ts
  html-iframe-has-title.ts
  html-no-duplicate-ids.ts
```

Ruby introduced an `a11y/` subdirectory that has no counterpart:

```
# Ruby (current)
rules/
  a11y/alt_text.rb          → rule_name: "alt-text"
  a11y/iframe_has_title.rb  → rule_name: "a11y/iframe-has-title"
  html/no_duplicate_id.rb   → rule_name: "html/no-duplicate-id"
```

### 2. All 8 rule names differ from TypeScript

| Ruby rule name | TypeScript rule name | Difference |
|---|---|---|
| `alt-text` | `html-img-require-alt` | Name completely different; no category prefix |
| `a11y/iframe-has-title` | `html-iframe-has-title` | Category: `a11y/` vs `html-` |
| `html/attribute-quotes` | `html-attribute-double-quotes` | Name differs |
| `html/lowercase-tags` | `html-tag-name-lowercase` | Name differs |
| `html/no-duplicate-attributes` | `html-no-duplicate-attributes` | Separator only (`/` vs `-`) |
| `html/no-duplicate-id` | `html-no-duplicate-ids` | Singular `id` vs plural `ids` |
| `html/no-positive-tabindex` | `html-no-positive-tab-index` | `tabindex` vs `tab-index` |
| `html/void-element-style` | `html-no-self-closing` | Name completely different |

### 3. Separator character differs

- TypeScript: `html-no-duplicate-ids` (hyphen only)
- Ruby: `html/no-duplicate-id` (slash between category and name)

### 4. Internal inconsistency

`alt-text` has no category prefix while all other Ruby rules do. This is inconsistent even within the Ruby implementation.

### 5. Directory structure differs

TypeScript uses a flat `rules/` directory. Ruby uses category subdirectories (`rules/html/`, `rules/a11y/`).

## Design Decisions

### Separator Character

Use `-` (hyphen) as the sole separator in rule names, matching TypeScript exactly.

- TypeScript: `html-no-duplicate-ids`
- Ruby (new): `html-no-duplicate-ids`

This ensures rule names are identical across both implementations. Users can use the same rule names in `.herb.yml` regardless of which tool they use.

### Directory Layout

Use a flat `rules/` directory, matching TypeScript. File names follow the rule name in snake_case:

```
# Target structure
rules/
  base.rb
  visitor_rule.rb
  rule_methods.rb
  node_helpers.rb
  html_img_require_alt.rb
  html_iframe_has_title.rb
  html_attribute_double_quotes.rb
  html_tag_name_lowercase.rb
  html_no_duplicate_attributes.rb
  html_no_duplicate_ids.rb
  html_no_positive_tab_index.rb
  html_no_self_closing.rb
```

### Module Namespace

Remove category sub-modules (`Html::`, `A11y::`) and place rule classes directly under `Rules::`:

```ruby
# Before
module Herb::Lint::Rules::Html
  class NoDuplicateIds < VisitorRule
    def self.rule_name = "html/no-duplicate-ids"
  end
end

# After
module Herb::Lint::Rules
  class HtmlNoDuplicateIds < VisitorRule
    def self.rule_name = "html-no-duplicate-ids"
  end
end
```

Class names embed the category prefix (e.g., `HtmlNoDuplicateIds`), keeping them self-descriptive without requiring a sub-module.

## Rule Name Mapping

Complete mapping from current Ruby names to target names (= TypeScript names):

| Current Ruby | Target Ruby (= TypeScript) | File name (new) | Class name (new) |
|---|---|---|---|
| `alt-text` | `html-img-require-alt` | `html_img_require_alt.rb` | `HtmlImgRequireAlt` |
| `a11y/iframe-has-title` | `html-iframe-has-title` | `html_iframe_has_title.rb` | `HtmlIframeHasTitle` |
| `html/attribute-quotes` | `html-attribute-double-quotes` | `html_attribute_double_quotes.rb` | `HtmlAttributeDoubleQuotes` |
| `html/lowercase-tags` | `html-tag-name-lowercase` | `html_tag_name_lowercase.rb` | `HtmlTagNameLowercase` |
| `html/no-duplicate-attributes` | `html-no-duplicate-attributes` | `html_no_duplicate_attributes.rb` | `HtmlNoDuplicateAttributes` |
| `html/no-duplicate-id` | `html-no-duplicate-ids` | `html_no_duplicate_ids.rb` | `HtmlNoDuplicateIds` |
| `html/no-positive-tabindex` | `html-no-positive-tab-index` | `html_no_positive_tab_index.rb` | `HtmlNoPositiveTabIndex` |
| `html/void-element-style` | `html-no-self-closing` | `html_no_self_closing.rb` | `HtmlNoSelfClosing` |

## Tasks

### Task 1: Flatten directory structure

- [x] Move `rules/a11y/alt_text.rb` → `rules/html_img_require_alt.rb`
- [x] Move `rules/a11y/iframe_has_title.rb` → `rules/html_iframe_has_title.rb`
- [x] Move `rules/html/attribute_quotes.rb` → `rules/html_attribute_double_quotes.rb`
- [x] Move `rules/html/lowercase_tags.rb` → `rules/html_tag_name_lowercase.rb`
- [x] Move `rules/html/no_duplicate_attributes.rb` → `rules/html_no_duplicate_attributes.rb`
- [x] Move `rules/html/no_duplicate_id.rb` → `rules/html_no_duplicate_ids.rb`
- [x] Move `rules/html/no_positive_tabindex.rb` → `rules/html_no_positive_tab_index.rb`
- [x] Move `rules/html/void_element_style.rb` → `rules/html_no_self_closing.rb`
- [x] Remove empty `rules/a11y/` directory
- [x] Remove empty `rules/html/` directory
- [x] Update `require_relative` statements in `lib/herb/lint.rb`

### Task 2: Update module namespaces and class names

- [x] Remove `Rules::A11y` module; move classes to `Rules::`
- [x] Remove `Rules::Html` module; move classes to `Rules::`
- [x] Rename classes with category prefix (e.g., `AltText` → `HtmlImgRequireAlt`)
- [x] Update `RuleRegistry.builtin_rules` with new class references

### Task 3: Rename rule names to match TypeScript

- [x] `alt-text` → `html-img-require-alt`
- [x] `a11y/iframe-has-title` → `html-iframe-has-title`
- [x] `html/attribute-quotes` → `html-attribute-double-quotes`
- [x] `html/lowercase-tags` → `html-tag-name-lowercase`
- [x] `html/no-duplicate-attributes` → `html-no-duplicate-attributes`
- [x] `html/no-duplicate-id` → `html-no-duplicate-ids`
- [x] `html/no-positive-tabindex` → `html-no-positive-tab-index`
- [x] `html/void-element-style` → `html-no-self-closing`
- [x] Update all `rule_name` method return values

### Task 4: Update tests

- [x] Move and rename spec files to match new rule file names
- [x] Remove empty `spec/rules/a11y/` directory
- [x] Remove empty `spec/rules/html/` directory
- [x] Update all test assertions that reference rule names
- [x] Update RBS type definition files

### Task 5: Update documentation

- [x] Update rule reference table in `docs/design/herb-lint-design.md`
- [x] Update `docs/tasks/phase-8-rule-expansion.md` rule names
- [x] Update `docs/tasks/README.md` if it references specific rule names

### Task 6: Verify

- [x] `cd herb-lint && ./bin/rspec` — all tests pass
- [x] `cd herb-lint && ./bin/steep check` — type checking passes
- [x] `cd herb-lint && ./bin/rubocop` — no offenses

## References

- TypeScript rule reference: `docs/design/herb-lint-design.md` (Rule List section)
- TypeScript source: https://github.com/marcoroth/herb/tree/main/javascript/packages/linter/src/rules
