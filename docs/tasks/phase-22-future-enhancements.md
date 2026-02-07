# Future Enhancements (Post-MVP)

This document lists feature enhancements to consider implementing after MVP completion.

## Features Simplified in MVP

These features are implemented as simplified versions in the MVP. Consider expanding to full-spec versions in the future.

### 1. herb-config: Loader Search Path Extension

**Current State (MVP):**
- Search only `.herb.yml` in current directory
- Use default configuration if not found

**Future Enhancements:**
- [ ] Environment variable support (`HERB_CONFIG`, `HERB_NO_CONFIG`)
- [ ] Upward directory search (search for `.herb.yml` up to project root)
- [ ] XDG Base Directory specification support

**Priority:** Medium

**Implementation Complexity:** Low

---

### 2. herb-config: Validator Implementation

**Current State (MVP):**
- Validation omitted
- Invalid configuration detected by runtime errors

**Future Enhancements:**
- [ ] Type validation (parameter type checking)
- [ ] Glob pattern validation (syntax checking)
- [ ] Rule name validation (detect non-existent rule names)
- [ ] Severity validation (detect values other than "error", "warning")
- [ ] Helpful error messages

**Priority:** Medium

**Implementation Complexity:** Medium

**Reference:** `docs/design/herb-config-design.md` - Validator section

---

### 3. herb-core: PatternMatcher Separation

**Current State (MVP):**
- PatternMatcher functionality integrated within FileDiscovery

**Future Enhancements:**
- [ ] Separate as PatternMatcher class
- [ ] Independent testing
- [ ] Improved reusability

**Priority:** Low

**Implementation Complexity:** Low

**Reason:** Perform as refactoring when current code becomes complex

---

### 4. herb-lint: DirectiveParser & herb-disable-comment Meta-Rules

**Status:** ✅ Implemented in [Phase 9](./phase-9-inline-directives.md)

~~**Current State (MVP):**~~
~~- Inline directives (`herb:disable`) not implemented~~

- [x] DirectiveParser implementation (stateless class methods in herb-lint)
- [x] Directives data object with `ignore_file?` and `disabled_at?` queries
- [x] Linter integration with `filter_offenses` and Context updates
- [x] `--ignore-disable-comments` CLI option
- [x] 6 herb-disable-comment meta-rules (non-excludable)

---

### 5. herb-lint: LinterFactory Implementation

**Current State (MVP):**
- Runner directly generates Linter

**Future Enhancements:**
- [ ] LinterFactory class implementation
- [ ] Extract rule selection logic
- [ ] Improve testability

**Priority:** Low

**Implementation Complexity:** Low

**Reason:** YAGNI principle. Direct generation is sufficient for now. Introduce when it becomes complex.

**Reference:** `docs/design/herb-lint-design.md` - LinterFactory section

---

### 6. herb-lint: RuleRegistry Dynamic Discovery

**Current State (MVP):**
- Hard-coded rule registration

**Future Enhancements:**
- [ ] Implement `discover_rules` method
- [ ] Automatic discovery by directory scanning
- [ ] Dynamic loading using reflection

**Priority:** Medium

**Implementation Complexity:** Medium

**Timing:** Consider implementation when rule count exceeds 10

**Reference:** `docs/design/herb-lint-design.md` - RuleRegistry section

---

### 7. Multiple Reporter Implementations

**Current State (MVP):**
- Only SimpleReporter implemented

**Future Enhancements:**
- [ ] DetailedReporter (with detailed information)
- [ ] JsonReporter (JSON format output)
- [ ] GithubReporter (GitHub Actions format)
- [ ] Other CI/CD tool support

**Priority:** Medium

**Implementation Complexity:** Low

**Reference:** `docs/design/herb-lint-design.md` - Reporter section

---

### 8. Auto-fix Functionality (`--fix` / `--fix-unsafely` options)

**Status:** 📋 Scheduled as [Phase 15: Autofix](./phase-15-autofix.md)

Detailed design available: [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

**Depends on:** [Phase 14: herb-printer](./phase-14-herb-printer.md) (IdentityPrinter for AST-to-source serialization)

- [ ] AutofixContext and Offense changes
- [ ] RuleMethods autofix extensions
- [ ] NodeLocator implementation
- [ ] AutoFixer implementation
- [ ] Runner and CLI integration (`--fix`, `--fix-unsafely`)
- [ ] Autofix utility helpers
- [ ] Add autofix to existing rules

**Priority:** High (improves user experience)

**Implementation Complexity:** High

---

### 9. Custom Rule Loading

**Current State (MVP):**
- Custom rules not supported

**Future Enhancements:**
- [ ] CustomRuleLoader implementation
- [ ] Plugin mechanism
- [ ] Third-party rule support

**Priority:** Medium

**Implementation Complexity:** High

**Reference:** `docs/design/herb-lint-design.md` - CustomRuleLoader section

---

### 10. Parallel Processing

**Current State (MVP):**
- Each file processed sequentially

**Future Enhancements:**
- [ ] Parallel processing with multi-threading/multi-processing
- [ ] Performance improvement for large projects

**Priority:** Low

**Implementation Complexity:** Medium

---

## Priority Summary

### High Priority (Consider immediately after MVP)
1. ~~DirectiveParser & herb-disable-comment meta-rules (inline directives)~~ ✅ Phase 9
2. Auto-fix functionality — Phase 14 (herb-printer) → Phase 15 (autofix)

### Medium Priority (As needed)
1. Validator implementation (configuration file validation)
2. Loader search path extension (environment variables, upward search)
3. RuleRegistry dynamic discovery
4. Multiple Reporter implementations
5. Custom rule loading

### Low Priority (When needed)
1. PatternMatcher separation
2. LinterFactory implementation
3. Parallel processing

---

## Add MVP Notes to Design Documents (TODO)

Consider adding notes about MVP simplified implementations to the following design documents:

- [ ] `docs/design/herb-config-design.md` - Loader, Validator sections
- [ ] `docs/design/herb-core-design.md` - PatternMatcher, DirectiveParser sections
- [ ] `docs/design/herb-lint-design.md` - LinterFactory, RuleRegistry sections

**Format Example:**
```markdown
## MVP Implementation Note

In the MVP release:
- [Simplified implementation details]
- [Omitted features]

Full implementation will include:
- [Features to be added in full version]
```
