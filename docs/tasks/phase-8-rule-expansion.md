# Phase 8: herb-lint Rule Expansion

This phase focuses on expanding herb-lint's rule coverage beyond the MVP's 3 rules.
Only rules that have corresponding rules in the TypeScript herb-lint reference implementation are included.

## Current Status

| Category | Spec | Implemented | Remaining |
|----------|------|-------------|-----------|
| ERB rules | 13 | 0 | 13 |
| HTML rules | 31 | 8 | 23 |

**Implemented rules:**
- `html-attribute-double-quotes`
- `html-iframe-has-title`
- `html-img-require-alt`
- `html-no-duplicate-attributes`
- `html-no-duplicate-ids`
- `html-no-positive-tab-index`
- `html-no-self-closing`
- `html-tag-name-lowercase`

## Task Organization

Rules are prioritized by:
1. **Complexity**: Simple rules first to build momentum
2. **Fixable**: Fixable rules provide immediate user value
3. **Independence**: Rules without complex dependencies first

---

## Batch 1: Simple HTML Rules (3 rules)

### Task 8.1: `html-no-duplicate-attributes`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow duplicate attributes on the same element.

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div class="foo" class="bar">

<!-- Good -->
<div class="foo bar">
```

---

### Task 8.2: `html-tag-name-lowercase`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Enforce lowercase tag names.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<DIV></DIV>

<!-- Good -->
<div></div>
```

---

### Task 8.3: `html-no-positive-tab-index`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow positive tabindex values (accessibility anti-pattern).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button tabindex="1">Click</button>

<!-- Good -->
<button tabindex="0">Click</button>
<button tabindex="-1">Click</button>
```

---

## Batch 2: Void Elements & Basic A11y (2 rules)

### Task 8.4: `html-no-self-closing`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Consistent self-closing style for void elements.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad (with closing slash) -->
<br/>
<img src="photo.jpg" />

<!-- Good (no closing slash) -->
<br>
<img src="photo.jpg">
```

---

### Task 8.5: `html-iframe-has-title`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require title attribute on iframe elements.

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<iframe src="content.html"></iframe>

<!-- Good -->
<iframe src="content.html" title="Embedded content"></iframe>
```

---

## Batch 3: ERB Rules (1 rule)

### Task 8.6: `erb-comment-syntax`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Enforce ERB comment style (`<%#` vs `<% #`).

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<% # This is a comment %>

<!-- Good -->
<%# This is a comment %>
```

---

## Summary

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 3 | Simple HTML rules |
| Batch 2 | 2 | Void elements & A11y |
| Batch 3 | 1 | ERB rules |

**Total: 6 rules (6 completed, 0 remaining)**

After completing these batches:
- ERB rules: 1/13 implemented
- HTML rules: 8/31 implemented

## Verification

For each rule:
1. `cd herb-lint && ./bin/rspec` - All tests pass
2. `cd herb-lint && ./bin/steep check` - Type checking passes
3. Manual test with sample ERB files

## Related Documents

- [herb-lint Specification](../requirements/herb-lint.md) - Full rule list
- [herb-lint Design](../design/herb-lint-design.md) - Architecture
