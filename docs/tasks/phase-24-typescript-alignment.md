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

**Status:** ✅ Complete (Already Implemented)

**Location:** `herb-lint/lib/herb/lint/unnecessary_directive_detector.rb`

**Description:**
This rule exists in TypeScript and warns when a `herb:disable` comment doesn't actually suppress any violations.

**Implementation:**

- [x] Already implemented via `UnnecessaryDirectiveDetector`
  - [x] Integrated at Linter level in `Linter#build_lint_result`
  - [x] Rule name: `"herb-disable-comment-unnecessary"`
  - [x] Default severity: `"warning"`
  - [x] Detects unnecessary disable comments
  - [x] Handles `all` keyword cases
  - [x] Comprehensive test coverage (11 test cases)
  - [x] RBS type annotations present

**Architectural Decision:**

Unlike TypeScript which implements this as a separate rule class, the Ruby implementation uses `UnnecessaryDirectiveDetector` integrated at the Linter level. This design is intentional because:

1. The rule requires knowledge of which offenses were actually suppressed
2. Detection must happen after all rules run and offenses are filtered
3. Integration at Linter level provides the necessary context

This approach maintains equivalent functionality while working within Ruby's linter flow. Documented in `docs/design/herb-lint-rules.md`.

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/unnecessary_directive_detector_spec.rb
cd herb-lint && ./bin/rspec spec/herb/lint/linter_spec.rb:124
# All tests pass ✅
```

**Priority:** Medium

---

### Task 24.2: Verify and Implement html-no-space-in-tag Rule

**Status:** ✅ Complete

**Description:**
The TypeScript `html-no-space-in-tag` rule may be missing from Ruby. The Phase 16 task list mentions it, but the implementation file cannot be found.

**Investigation:**

- [x] Search for `html-no-space-in-tag` rule file
  - [x] Check `herb-lint/lib/herb/lint/rules/html/` directory
  - [x] Look for similar named rules
- [x] Review TypeScript implementation
  - [x] Understand what violations it detects
  - [x] Check autofix support

**Investigation Results:**

The `html-no-space-in-tag` rule is already fully implemented:

- [x] Implementation file: `herb-lint/lib/herb/lint/rules/html/no_space_in_tag.rb`
- [x] Test file: `herb-lint/spec/herb/lint/rules/html/no_space_in_tag_spec.rb`
- [x] Rule name: `"html-no-space-in-tag"`
- [x] Default severity: `"warning"`
- [x] Autofix support: `safe_autofixable = true`
- [x] Disabled by default: `enabled_by_default = false` (aligned with TypeScript)
- [x] Registered in RuleRegistry
- [x] All tests pass: 35 examples, 0 failures
- [x] RBS type annotations present

No additional implementation needed.

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

**Status:** ✅ Complete (Completed via Phase 18 Task S.4)

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_extra_newline.rb`

**Description:**
TypeScript version has autofix for `erb-no-extra-newline`, but Ruby didn't. This rule has been migrated to SourceRule (Phase 18) with full autofix support.

**Dependencies:**
- Phase 18: Source Rule Introduction (Task S.4) ✅ Complete

**Implementation:**

- [x] Verify Phase 18 progress
  - [x] Check if SourceRule base class is implemented ✅
  - [x] Check if Autofixer source phase is implemented ✅
- [x] Implement autofix after SourceRule migration
  - [x] Add `safe_autofixable? = true` ✅
  - [x] Implement source-level autofix ✅
  - [x] Remove extra newlines ✅
- [x] Add test cases ✅
- [x] Update RBS type annotations ✅

**Implementation Details:**
- Change base class from `Base` to `SourceRule`
- Rename `check` to `check_source` with signature `(source, context)`
- Add `safe_autofixable? = true`
- Replace `add_offense` with `add_offense_with_source_autofix`
- Implement `autofix_source` with offset verification
- Remove helper methods now provided by base class

**Tests:**
- Detection tests: 12 examples
- Autofix tests: 4 examples (single occurrence, multiple occurrences, EOF, offset verification)
- All tests pass: 20 examples, 0 failures

**Verification:**
```bash
cd herb-lint && ./bin/rspec spec/herb/lint/rules/erb/no_extra_newline_spec.rb
# 20 examples, 0 failures ✅
cd herb-lint && ./bin/steep check
```

**Completed:** 2026-02-11 (Commit: 0780bcb)

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

**Status:** ✅ Complete

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

**Decision:**

**Align with TypeScript implementation** - Change all 16 rules to use `error` severity.

**Rationale:**

1. **Project Goals:** Both CLAUDE.md and herb-lint-design.md explicitly state that the project provides "CLI compatibility with TypeScript counterparts" and "equivalent functionality"
2. **Consistency:** Users migrating between TypeScript and Ruby implementations expect the same behavior
3. **Configuration Override:** Users who prefer warnings can easily override severity in their `.herb.yml` configuration files
4. **Default Strictness:** TypeScript's stricter defaults encourage better code quality; users can relax rules if needed

**Implementation Plan:**
- Update all 16 rules' `default_severity` from `:warning` to `:error`
- Update corresponding test expectations
- Document the change in relevant files

**Considerations:**

- [x] Review project policy
  - [x] Prioritize full TypeScript compatibility ✅
  - [x] Maintain Ruby-specific judgment ❌
- [x] Consider rule nature
  - [x] Most rules address correctness issues that warrant `error` severity
- [x] Evaluate user impact
  - [x] Impact on existing `.herb.yml` configurations: Users can override if needed
  - [x] Impact on CI/CD pipelines: May catch more issues, which is desirable

**Post-Decision Actions:**
- Tasks 24.6-24.21 will update individual rule severities

**Priority:** High (prerequisite for other tasks)

---

### Tasks 24.6-24.21: Individual Rule Severity Updates

**Status:** ⏳ Pending (After Task 24.5 Decision)

**Description:**
If Task 24.5 decides to align with TypeScript, change each rule's `default_severity` to `error`.

#### Task 24.6: Change erb-no-empty-tags severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_empty_tags.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (20 examples, 0 failures)

#### Task 24.7: Change erb-no-extra-whitespace-inside-tags severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_extra_whitespace_inside_tags.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (28 examples, 0 failures)

#### Task 24.8: Change erb-no-output-control-flow severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/no_output_control_flow.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (18 examples, 0 failures)

#### Task 24.9: Change erb-require-whitespace-inside-tags severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/require_whitespace_inside_tags.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (37 examples, 0 failures)

#### Task 24.10: Change erb-strict-locals-required severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/erb/strict_locals_required.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (14 examples, 0 failures)

#### Task 24.11: Change html-anchor-require-href severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/anchor_require_href.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (12 examples, 0 failures)

#### Task 24.12: Change html-aria-label-is-well-formatted severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/aria_label_is_well_formatted.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (13 examples, 0 failures)

#### Task 24.13: Change html-attribute-equals-spacing severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_equals_spacing.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (18 examples, 0 failures)

#### Task 24.14: Change html-attribute-values-require-quotes severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/attribute_values_require_quotes.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (14 examples, 0 failures)

#### Task 24.15: Change html-avoid-both-disabled-and-aria-disabled severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/avoid_both_disabled_and_aria_disabled.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (12 examples, 0 failures)

#### Task 24.16: Change html-boolean-attributes-no-value severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/boolean_attributes_no_value.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (17 examples, 0 failures)

#### Task 24.17: Change html-no-empty-headings severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/no_empty_headings.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (16 examples, 0 failures)

#### Task 24.18: Change html-no-self-closing severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/no_self_closing.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (18 examples, 0 failures)

#### Task 24.19: Change html-no-title-attribute severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/no_title_attribute.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (11 examples, 0 failures)

#### Task 24.20: Change html-tag-name-lowercase severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/html/tag_name_lowercase.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (18 examples, 0 failures)

#### Task 24.21: Change svg-tag-name-capitalization severity to error

**Status:** ✅ Complete

**Location:** `herb-lint/lib/herb/lint/rules/svg/tag_name_capitalization.rb`

- [x] Change `default_severity` to `"error"`
- [x] Update test expectations
- [x] All tests pass (12 examples, 0 failures)

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

**Status:** ✅ Complete

**Description:**
Update related documentation to reflect Phase 24 changes.

**Files Updated:**

- [x] `herb-lint/README.md`
  - [x] Document all 52 rules with severity, fixable, and enabled status
  - [x] Update rule count (3 → 52)
  - [x] Add autofix, inline directives, and CLI options documentation
  - [x] Remove outdated MVP limitations section
- [x] `docs/requirements/herb-lint.md`
  - [x] Update rule list with actual implementations (52 rules across 5 categories)
  - [x] Reflect severity changes (16 rules changed from warning to error)
  - [x] Update post-MVP features section
- [x] `docs/tasks/README.md`
  - [x] Update Phase 24 status from 📋 to 🚧
- [x] `docs/tasks/phase-16-rule-autofix-expansion.md`
  - [x] Task 16.13 already marked as Complete (no changes needed)

**Verification:**
```bash
# Check for broken links
grep -r "herb-disable-comment-unnecessary" docs/
grep -r "html-no-space-in-tag" docs/
```

---

## Progress Summary

### Part A: Missing Rules (2 tasks)
- [x] 24.1: Implement herb-disable-comment-unnecessary (Already implemented)
- [x] 24.2: Verify/implement html-no-space-in-tag

### Part B: Autofix Alignment (2 tasks)
- [x] 24.3: Add autofix to erb-no-extra-newline (Completed via Phase 18)
- [ ] 24.4: Propose to TypeScript (optional)

### Part C: Severity Alignment (17 tasks)
- [x] 24.5: Decide severity policy
- [x] 24.6-24.21: Update individual rules (16 rules)

### Part D: Documentation & Alignment (3 tasks)
- [x] 24.22: Create analysis documents
- [x] 24.23: Align default enabled status (5 rules)
- [x] 24.24: Update README etc.

**Total: 24 tasks** (23 complete, 1 pending - Task 24.4 external)

---

## Recommended Implementation Order

1. ~~**Task 24.23** (High Priority): Align default enabled status (5 rules)~~ ✅ Complete
2. ~~**Task 24.2** (High Priority): Verify html-no-space-in-tag~~ ✅ Complete
3. ~~**Task 24.1** (Medium Priority): Implement herb-disable-comment-unnecessary~~ ✅ Complete (Already implemented)
4. ~~**Task 24.3** (Medium Priority): Add erb-no-extra-newline autofix~~ ✅ Complete (Completed via Phase 18)
5. ~~**Task 24.5** (High Priority): Decide severity policy~~ ✅ Complete
6. ~~**Tasks 24.6-24.21**: Update severities (after policy decision)~~ ✅ Complete
7. ~~**Task 24.24**: Update documentation~~ ✅ Complete
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
