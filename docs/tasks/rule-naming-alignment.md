# Task: Align Rule Directory Structure and Naming with TypeScript Reference

Align the Ruby lint rule directory structure and naming conventions with the TypeScript reference implementation (`@herb-tools/linter`).

## Background

The current Ruby implementation diverges from the TypeScript reference in rule directory layout, category structure, and rule naming. Since both implementations share the same `.herb.yml` configuration file format, rule names must be compatible.

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

## Tasks

### Task 1: Move `a11y/` rules to `html/`

- [x] Move `rules/a11y/alt_text.rb` to `rules/html/` with appropriate rename
- [x] Move `rules/a11y/iframe_has_title.rb` to `rules/html/`
- [x] Remove empty `rules/a11y/` directory
- [x] Update `require_relative` statements in `lib/herb/lint.rb`
- [x] Update module namespace from `Rules::A11y::` to `Rules::Html::`
- [x] Update `RuleRegistry.builtin_rules`
- [x] Move and update corresponding spec files
- [x] Move and update corresponding RBS type definition files

### Task 2: Rename rule names to match TypeScript

- [x] `alt-text` → `html/img-require-alt`
- [x] `a11y/iframe-has-title` → `html/iframe-has-title`
- [x] `html/attribute-quotes` → `html/attribute-double-quotes`
- [x] `html/lowercase-tags` → `html/tag-name-lowercase`
- [x] `html/no-duplicate-id` → `html/no-duplicate-ids`
- [x] `html/no-positive-tabindex` → `html/no-positive-tab-index`
- [x] `html/void-element-style` → `html/no-self-closing`
- [x] `html/no-duplicate-attributes` — no change needed (separator only)
- [x] Update all `rule_name` method return values
- [x] Update all test assertions that reference rule names
- [x] Rename Ruby source files to match new rule names where appropriate

### Task 3: Update documentation

- [x] Update rule reference table in `docs/design/herb-lint-design.md`
- [x] Update `docs/tasks/phase-8-rule-expansion.md` rule names
- [x] Update `docs/tasks/README.md` if it references specific rule names

### Task 4: Verify

- [ ] `cd herb-lint && ./bin/rspec` — all tests pass
- [ ] `cd herb-lint && ./bin/steep check` — type checking passes
- [ ] `cd herb-lint && ./bin/rubocop` — no offenses

## Design Decision: Separator Character

TypeScript uses `-` (hyphen) as the sole separator: `html-no-duplicate-ids`.

Ruby currently uses `/` (slash) between category and name: `html/no-duplicate-id`.

**Recommendation:** Keep the `/` separator in Ruby rule names (e.g., `html/no-duplicate-ids` instead of `html-no-duplicate-ids`). The slash-separated format is idiomatic for Ruby tools (similar to RuboCop's `Style/FrozenStringLiteralComment`) and is already established in the codebase. The mapping between Ruby (`html/`) and TypeScript (`html-`) separators is straightforward and can be handled at the configuration layer if cross-tool compatibility is needed.

## References

- TypeScript rule reference: `docs/design/herb-lint-design.md` (Rule List section)
- TypeScript source: https://github.com/marcoroth/herb/tree/main/javascript/packages/linter/src/rules
