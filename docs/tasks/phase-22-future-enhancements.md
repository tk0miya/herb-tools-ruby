# Future Enhancements (Post-MVP)

This document lists feature enhancements to consider implementing after MVP completion.

## Features Simplified in MVP

These features are implemented as simplified versions in the MVP. Consider expanding to full-spec versions in the future.

### 1. herb-config: Validator Implementation

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

### 2. herb-core: PatternMatcher Separation

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

### 3. herb-lint: DirectiveParser & herb-disable-comment Meta-Rules

**Status:** ✅ Implemented in [Phase 9](./phase-9-inline-directives.md)

~~**Current State (MVP):**~~
~~- Inline directives (`herb:disable`) not implemented~~

- [x] DirectiveParser implementation (stateless class methods in herb-lint)
- [x] Directives data object with `ignore_file?` and `disabled_at?` queries
- [x] Linter integration with `filter_offenses` and Context updates
- [x] `--ignore-disable-comments` CLI option
- [x] 6 herb-disable-comment meta-rules (non-excludable)

---

### 4. herb-lint: LinterFactory Implementation

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

### 5. herb-lint: RuleRegistry Dynamic Discovery

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

### 6. Multiple Reporter Implementations

**Current State (MVP):**
- Only SimpleReporter implemented

**Future Enhancements:**
- [x] DetailedReporter (with detailed information)
- [x] JsonReporter (JSON format output)
- [x] GithubReporter (GitHub Actions format)
- [ ] Other CI/CD tool support

**Priority:** Medium

**Implementation Complexity:** Low

**Reference:** `docs/design/herb-lint-design.md` - Reporter section

---

### 7. Auto-fix Functionality (`--fix` / `--fix-unsafely` options)

**Status:** 📋 Scheduled as [Phase 15: Autofix](./phase-15-autofix.md)

Detailed design available: [herb-lint-autofix-design.md](../design/herb-lint-autofix-design.md)

**Depends on:** [Phase 14: herb-printer](./phase-14-herb-printer.md) (IdentityPrinter for AST-to-source serialization)

- [ ] AutofixContext and Offense changes
- [ ] RuleMethods autofix extensions
- [ ] NodeLocator implementation
- [ ] Autofixer implementation
- [ ] Runner and CLI integration (`--fix`, `--fix-unsafely`)
- [ ] Autofix utility helpers
- [ ] Add autofix to existing rules

**Priority:** High (improves user experience)

**Implementation Complexity:** High

---

### 8. Custom Rule Loading

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

### 9. Parallel Processing

**Current State (MVP):**
- Each file processed sequentially

**Future Enhancements:**
- [ ] Parallel processing with multi-threading/multi-processing
- [ ] Performance improvement for large projects

**Priority:** Low

**Implementation Complexity:** Medium

---

### 10. Formatter include/exclude Patterns

**Status:** ⏸️ Blocked by herb-format gem implementation

**Location:** `herb-format/lib/herb/format/config.rb` (future)

**Future Enhancements:**
- [ ] Read `formatter.include` from config
- [ ] Read `formatter.exclude` from config
- [ ] Merge with top-level `files` patterns
- [ ] Add unit tests

**Configuration Example:**

```yaml
# .herb.yml
files:
  exclude:
    - 'vendor/**/*'

formatter:
  include:
    - '**/*.html.erb'
  exclude:
    - 'tmp/**/*'
```

**Priority:** Medium

**Implementation Complexity:** Low

**Dependencies:** herb-format gem implementation

**Reference:** [Phase 17: Advanced Configuration Features](./phase-17-advanced-config.md) - Originally Task 17.6

---

### 11. Formatter Rewriter Hooks

**Status:** ⏸️ Blocked by herb-format gem implementation

**Location:** `herb-format/lib/herb/format/rewriter_pipeline.rb` (future)

**Future Enhancements:**
- [ ] Implement RewriterRegistry
- [ ] Implement pre-format rewriter pipeline
- [ ] Implement post-format rewriter pipeline
- [ ] Add unit tests
- [ ] Document rewriter API

**Configuration Example:**

```yaml
# .herb.yml
formatter:
  rewriter:
    pre:
      - 'normalize-whitespace'
      - 'custom-preprocessor'
    post:
      - 'trim-trailing-spaces'
      - 'ensure-final-newline'
```

**Rewriter API:**

```ruby
module Herb
  module Format
    module Rewriter
      class Base
        # @rbs ast: Herb::AST::Node
        def rewrite(ast) #: Herb::AST::Node
          # Transform AST
        end
      end
    end
  end
end
```

**Priority:** Low

**Implementation Complexity:** Medium

**Dependencies:** herb-format gem implementation

**Reference:** [Phase 17: Advanced Configuration Features](./phase-17-advanced-config.md) - Originally Task 17.7

---

## Priority Summary

### High Priority (Consider immediately after MVP)
1. ~~DirectiveParser & herb-disable-comment meta-rules (inline directives)~~ ✅ Phase 9
2. Auto-fix functionality — Phase 14 (herb-printer) → Phase 15 (autofix)

### Medium Priority (As needed)
1. Validator implementation (configuration file validation)
2. RuleRegistry dynamic discovery
3. Multiple Reporter implementations
4. Custom rule loading
5. Formatter include/exclude patterns (requires herb-format)

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
