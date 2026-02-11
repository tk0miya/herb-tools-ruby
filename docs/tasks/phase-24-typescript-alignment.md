# Phase 24: TypeScript Implementation Alignment

This phase aligns the Ruby implementation with the original TypeScript implementation to ensure full compatibility.

**Reference Documents:**
- [HERB_LINT_RULES_COMPLETE_ANALYSIS.md](../../HERB_LINT_RULES_COMPLETE_ANALYSIS.md) - Complete comparison analysis
- [RULES_COMPARISON.md](../../RULES_COMPARISON.md) - Detailed differences

**Prerequisites:**
- Phase 15 (Autofix infrastructure) - Complete
- Phase 16 (Rule autofix expansion) - Nearly complete

---

## Overview

Differences between TypeScript and Ruby implementations:
- **Missing rules**: 1-2 rules
- **Autofix differences**: 2 rules
- **Severity differences**: 16 rules
- **Rule type differences**: Architectural variation (no functional impact)

---

## Part A: Missing Rules Implementation

### Task 24.1: Implement herb-disable-comment-unnecessary Rule

**Status:** ⏳ Pending

**Location:** `herb-lint/lib/herb/lint/rules/herb/disable_comment_unnecessary.rb`

**Description:**
This rule exists in TypeScript but is missing in Ruby. It warns when a `herb:disable` comment doesn't actually suppress any violations.

**Implementation:**

- [ ] Create `Herb::Lint::Rules::Herb::DisableCommentUnnecessary` class
  - [ ] Extend `DirectiveRule`
  - [ ] Set `rule_name = "herb-disable-comment-unnecessary"`
  - [ ] Set `default_severity = "warning"`
  - [ ] Set `description`
- [ ] Implement detection logic (reference TypeScript implementation)
  - [ ] Check if disable comment actually suppresses any violations
  - [ ] Report offense if no violations are suppressed
- [ ] Register in RuleRegistry
- [ ] Create test cases
  - [ ] Detect unnecessary disable comments
  - [ ] Don't report necessary disable comments
  - [ ] Handle `all` keyword cases
- [ ] Add RBS type annotations

**TypeScript Reference:**
```typescript
// /tmp/herb-original/javascript/packages/linter/src/rules/herb-disable-comment-unnecessary.ts
```

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/rules/herb/disable_comment_unnecessary_spec.rb
cd herb-lint && ./bin/steep check
```

**Priority:** Medium

---

### Task 24.2: Verify and Implement html-no-space-in-tag Rule

**Status:** ⏳ Pending (Investigation Required)

**Description:**
The TypeScript `html-no-space-in-tag` rule may be missing from Ruby. The Phase 16 task list mentions it, but the implementation file cannot be found.

**Investigation:**

- [ ] Search for `html-no-space-in-tag` rule file
  - [ ] Check `herb-lint/lib/herb/lint/rules/html/` directory
  - [ ] Look for similar named rules
- [ ] Review TypeScript implementation
  - [ ] Understand what violations it detects
  - [ ] Check autofix support

**If Implementation is Needed:**

- [ ] Create `Herb::Lint::Rules::Html::NoSpaceInTag` class
  - [ ] Extend `VisitorRule`
  - [ ] Set `rule_name = "html-no-space-in-tag"`
  - [ ] Set `default_severity = "error"`
  - [ ] Set `safe_autofixable? = true`
- [ ] Implement detection logic
  - [ ] Check for illegal spaces immediately after tag names
- [ ] Implement autofix
- [ ] Register in RuleRegistry
- [ ] Create test cases
- [ ] Add RBS type annotations

**TypeScript Reference:**
```typescript
// /tmp/herb-original/javascript/packages/linter/src/rules/html-no-space-in-tag.ts
```

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/rules/html/no_space_in_tag_spec.rb
cd herb-lint && ./bin/steep check
```

**Priority:** High (if missing from Phase 16)

---

## Part B: Autofix Alignment

### Task 24.3: Add Autofix to erb-no-extra-newline

**Status:** ⏳ Pending (Coordinate with Phase 18)

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_extra_newline.rb`

**Description:**
TypeScript version has autofix for `erb-no-extra-newline`, but Ruby doesn't. However, this rule is planned for migration to SourceRule (Phase 18).

**Dependencies:**
- Phase 18: Source Rule Introduction (Task 18.4)

**Implementation:**

- [ ] Verify Phase 18 progress
  - [ ] Check if SourceRule base class is implemented
  - [ ] Check if Autofixer source phase is implemented
- [ ] Implement autofix after SourceRule migration
  - [ ] Add `safe_autofixable? = true`
  - [ ] Implement source-level autofix
  - [ ] Remove extra newlines
- [ ] Add test cases
- [ ] Update RBS type annotations

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/rules/erb/no_extra_newline_spec.rb --tag autofix
cd herb-lint && ./bin/steep check
```

**Priority:** Medium (after Phase 18 completion)

---

### Task 24.4: Propose erb-no-empty-tags Autofix to TypeScript (Optional)

**Status:** ⏳ Pending (External Project)

**Description:**
Ruby has autofix for `erb-no-empty-tags`, but TypeScript doesn't. This is a Ruby-first implementation.

**Action:**

- [ ] Create Issue or PR in TypeScript repository
  - [ ] Provide Ruby autofix implementation as reference
  - [ ] Explain usefulness of the feature
- [ ] Or maintain as Ruby-specific implementation

**Priority:** Low (no impact on Ruby version)

---

## Part C: Severity Alignment

### Task 24.5: Decide Severity Alignment Policy

**Status:** ⏳ Pending (Design Decision Required)

**Description:**
16 rules use `warning` in Ruby but `error` in TypeScript. Project policy needs to be decided: align with TypeScript or maintain Ruby's independent judgment.

**Rules with Differences:**
1. `erb-no-empty-tags`
2. `erb-no-extra-whitespace-inside-tags`
3. `erb-no-output-control-flow`
4. `erb-require-whitespace-inside-tags`
5. `erb-strict-locals-required`
6. `html-anchor-require-href`
7. `html-aria-label-is-well-formatted`
8. `html-attribute-equals-spacing`
9. `html-attribute-values-require-quotes`
10. `html-avoid-both-disabled-and-aria-disabled`
11. `html-boolean-attributes-no-value`
12. `html-no-empty-headings`
13. `html-no-self-closing`
14. `html-no-title-attribute`
15. `html-tag-name-lowercase`
16. `svg-tag-name-capitalization`

**Considerations:**

- [ ] Review project policy
  - [ ] Prioritize full TypeScript compatibility?
  - [ ] Maintain Ruby-specific judgment?
- [ ] Consider rule nature
  - [ ] Syntax errors → `error` is appropriate
  - [ ] Style violations → `warning` is appropriate
- [ ] Evaluate user impact
  - [ ] Impact on existing `.herb.yml` configurations
  - [ ] Impact on CI/CD pipelines

**Post-Decision Actions:**
- Tasks 24.6-24.21 will update individual rule severities

**Priority:** High (prerequisite for other tasks)

---

### Tasks 24.6-24.21: Individual Rule Severity Updates

**Status:** ⏳ Pending (After Task 24.5 Decision)

**Description:**
If Task 24.5 decides to align with TypeScript, change each rule's `default_severity` to `error`.

#### Task 24.6: Change erb-no-empty-tags severity to error

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_empty_tags.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations
- [ ] Update documentation

#### Task 24.7: Change erb-no-extra-whitespace-inside-tags severity to error

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_extra_whitespace_inside_tags.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.8: Change erb-no-output-control-flow severity to error

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_output_control_flow.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.9: Change erb-require-whitespace-inside-tags severity to error

**Location:** `herb-lint/lib/herb/lint/rules/erb/require_whitespace_inside_tags.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.10: Change erb-strict-locals-required severity to error

**Location:** `herb-lint/lib/herb/lint/rules/erb/strict_locals_required.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.11: Change html-anchor-require-href severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/anchor_require_href.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.12: Change html-aria-label-is-well-formatted severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/aria_label_is_well_formatted.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.13: Change html-attribute-equals-spacing severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_equals_spacing.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.14: Change html-attribute-values-require-quotes severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_values_require_quotes.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.15: Change html-avoid-both-disabled-and-aria-disabled severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/avoid_both_disabled_and_aria_disabled.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.16: Change html-boolean-attributes-no-value severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/boolean_attributes_no_value.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.17: Change html-no-empty-headings severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/no_empty_headings.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.18: Change html-no-self-closing severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/no_self_closing.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.19: Change html-no-title-attribute severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/no_title_attribute.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.20: Change html-tag-name-lowercase severity to error

**Location:** `herb-lint/lib/herb/lint/rules/html/tag_name_lowercase.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

#### Task 24.21: Change svg-tag-name-capitalization severity to error

**Location:** `herb-lint/lib/herb/lint/rules/svg/tag_name_capitalization.rb`

- [ ] Change `default_severity` to `"error"`
- [ ] Update test expectations

**Batch Verification:**
```bash
cd herb-lint && ./bin/rspec
cd herb-lint && ./bin/steep check
```

---

## Part D: Documentation Updates

### Task 24.22: Add Analysis Documents

**Status:** ✅ Complete

**Location:** Project root

Completed:
- [x] `HERB_LINT_RULES_COMPLETE_ANALYSIS.md` - Complete comparison analysis
- [x] `RUBY_RULES_ANALYSIS.md` - Ruby implementation details
- [x] `TYPESCRIPT_RULES_ANALYSIS.md` - TypeScript implementation details
- [x] `RULES_COMPARISON.md` - Detailed comparison

---

### Task 24.23: Align Default Enabled Status

**Status:** ✅ Complete

**Description:**
5 rules are disabled by default in TypeScript but enabled in Ruby. Align the behavior.

**Rules to Disable by Default:**

1. `erb-strict-locals-required` - Opt-in Rails feature
2. `html-navigation-has-label` - May have false positives
3. `html-no-block-inside-inline` - Complex nesting rules
4. `html-no-space-in-tag` - Controversial rule (already implemented)
5. `html-no-title-attribute` - Controversial accessibility rule

**Note:** All 5 rules were verified against the TypeScript implementation. Each rule in TypeScript has `enabled: false` in its `defaultConfig` getter.

**Implementation:**

- [x] Add `def self.enabled_by_default? = false` to each rule (5 rules)
- [x] Update RuleRegistry to respect `enabled_by_default?`
- [x] Update tests to verify disabled-by-default behavior
- [x] Update RBS type signatures
- [x] Verify alignment with TypeScript implementation
- [x] Update documentation

**Files to Modify:**

- `herb-lint/lib/herb/lint/rules/erb/strict_locals_required.rb`
- `herb-lint/lib/herb/lint/rules/html/navigation_has_label.rb`
- `herb-lint/lib/herb/lint/rules/html/no_block_inside_inline.rb`
- `herb-lint/lib/herb/lint/rules/html/no_space_in_tag.rb`
- `herb-lint/lib/herb/lint/rules/html/no_title_attribute.rb`
- `herb-lint/lib/herb/lint/rule_registry.rb` (if changes needed)

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/rule_registry_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/config_spec.rb
```

**Priority:** High

---

### Task 24.24: Update README and Documentation

**Status:** ⏳ Pending (After Phase 24 Completion)

**Description:**
Update related documentation to reflect Phase 24 changes.

**Files to Update:**

- [ ] `herb-lint/README.md`
  - [ ] Document newly added rules
  - [ ] Update rule count (51 → 52+)
- [ ] `docs/requirements/herb-lint.md`
  - [ ] Update rule list
  - [ ] Reflect severity changes
- [ ] `docs/tasks/README.md`
  - [ ] Add Phase 24
  - [ ] Update task counts
- [ ] `docs/tasks/phase-16-rule-autofix-expansion.md`
  - [ ] Update Task 16.13 completion status

**Verification:**
```bash
# Check for broken links
grep -r "herb-disable-comment-unnecessary" docs/
grep -r "html-no-space-in-tag" docs/
```

---

## Progress Summary

### Part A: Missing Rules (2 tasks)
- [ ] 24.1: Implement herb-disable-comment-unnecessary
- [ ] 24.2: Verify/implement html-no-space-in-tag

### Part B: Autofix Alignment (2 tasks)
- [ ] 24.3: Add autofix to erb-no-extra-newline (Phase 18 coordination)
- [ ] 24.4: Propose to TypeScript (optional)

### Part C: Severity Alignment (17 tasks)
- [ ] 24.5: Decide severity policy
- [ ] 24.6-24.21: Update individual rules (16 rules)

### Part D: Documentation & Alignment (3 tasks)
- [x] 24.22: Create analysis documents
- [x] 24.23: Align default enabled status (5 rules)
- [ ] 24.24: Update README etc.

**Total: 24 tasks** (2 complete, 22 pending)

---

## Recommended Implementation Order

1. **Task 24.23** (High Priority): Align default enabled status (5 rules)
2. **Task 24.2** (High Priority): Verify html-no-space-in-tag
3. **Task 24.1** (Medium Priority): Implement herb-disable-comment-unnecessary
4. **Task 24.5** (High Priority): Decide severity policy
5. **Tasks 24.6-24.21**: Update severities (after policy decision)
6. **Task 24.3**: Add erb-no-extra-newline autofix (after Phase 18)
7. **Task 24.24**: Update documentation
8. **Task 24.4**: Propose to TypeScript (optional)

---

## Verification

### Full Test Suite

```bash
# Test all rules
cd herb-lint && ./bin/rspec

# Type check
cd herb-lint && ./bin/steep check

# Rubocop
cd herb-lint && ./bin/rubocop
```

### Integration Tests

```bash
# CLI functionality
cd herb-lint && ./bin/rspec spec/herb/lint/cli_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/runner_spec.rb
```

### Manual Testing

```bash
# Verify rule count
herb-lint --help | grep "Rules:"

# Test new rule behavior
echo '<div>test</div><%# herb:disable html-img-require-alt %>' > test.erb
herb-lint test.erb
```

---

## Related Documents

- [Phase 15: Autofix](./phase-15-autofix.md)
- [Phase 16: Rule Autofix Expansion](./phase-16-rule-autofix-expansion.md)
- [Phase 18: Source Rule Introduction](./phase-18-source-rule.md)
- [Phase 21: Review Linter Rules](./phase-21-review-linter-rules.md)
- [herb-lint Specification](../requirements/herb-lint.md)
- [Autofix Design](../design/herb-lint-autofix-design.md)
- [Complete Rule Analysis](../../HERB_LINT_RULES_COMPLETE_ANALYSIS.md)
