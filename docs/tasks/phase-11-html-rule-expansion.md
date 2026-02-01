# Phase 11: HTML Rule Expansion

This phase implements the remaining 23 HTML rules from the TypeScript reference implementation.

## Current Status

| Category | Spec | Implemented | Remaining |
|----------|------|-------------|-----------|
| HTML rules | 31 | 8 | 23 |

**Implemented rules (Phase 4/8):**
- `html-attribute-double-quotes`
- `html-iframe-has-title`
- `html-img-require-alt`
- `html-no-duplicate-attributes`
- `html-no-duplicate-ids`
- `html-no-positive-tab-index`
- `html-no-self-closing`
- `html-tag-name-lowercase`

## Task Organization

Rules are grouped by theme and sorted by complexity within each batch.

---

## Batch 1: Attribute Rules (5 rules)

### Task 11.1: `html-attribute-equals-spacing`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow spaces around `=` in attribute assignments.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<div class = "foo">
<div class ="foo">
<div class= "foo">

<!-- Good -->
<div class="foo">
```

---

### Task 11.2: `html-attribute-values-require-quotes`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require quotes around attribute values.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<div class=foo>

<!-- Good -->
<div class="foo">
<div class='foo'>
```

---

### Task 11.3: `html-boolean-attributes-no-value`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Boolean attributes should not have values.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<input disabled="disabled">
<input disabled="true">

<!-- Good -->
<input disabled>
```

---

### Task 11.4: `html-no-empty-attributes`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow empty attribute values (except where semantically valid like `alt=""`).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div class="">
<input type="">

<!-- Good -->
<div class="container">
<img alt="">
```

---

### Task 11.5: `html-no-underscores-in-attribute-names`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow underscores in HTML attribute names (use hyphens instead).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div data_value="foo">

<!-- Good -->
<div data-value="foo">
```

---

## Batch 2: Element Structure Rules (5 rules)

### Task 11.6: `html-anchor-require-href`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require `href` attribute on anchor (`<a>`) elements.

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<a>Click here</a>
<a name="anchor">Section</a>

<!-- Good -->
<a href="/page">Click here</a>
<a href="#">Click here</a>
```

---

### Task 11.7: `html-no-space-in-tag`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow spaces between `<` and tag name.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
< div>content</ div>

<!-- Good -->
<div>content</div>
```

---

### Task 11.8: `html-no-title-attribute`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow use of `title` attribute (accessibility concern: unreliable for screen readers and touch devices).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<span title="More info">Hover me</span>

<!-- Good -->
<span>More info available</span>
```

---

### Task 11.9: `html-no-duplicate-meta-names`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow duplicate `<meta>` elements with the same `name` attribute.

**Complexity:** Medium

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<meta name="description" content="First">
<meta name="description" content="Second">

<!-- Good -->
<meta name="description" content="Page description">
<meta name="viewport" content="width=device-width">
```

---

### Task 11.10: `html-no-nested-links`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow nesting of anchor (`<a>`) elements.

**Complexity:** Medium

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<a href="/outer">
  <a href="/inner">Nested link</a>
</a>

<!-- Good -->
<a href="/page">Link</a>
```

---

## Batch 3: ARIA Accessibility Rules (6 rules)

### Task 11.11: `html-aria-attribute-must-be-valid`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** ARIA attributes must be valid (known `aria-*` attributes only).

**Complexity:** Medium (requires list of valid ARIA attributes)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div aria-labelled="Name">

<!-- Good -->
<div aria-label="Name">
<div aria-labelledby="name-id">
```

---

### Task 11.12: `html-aria-label-is-well-formatted`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** `aria-label` values should be well-formatted (not empty, not just whitespace, starts with uppercase or is a known pattern).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button aria-label="">Submit</button>
<button aria-label="   ">Submit</button>

<!-- Good -->
<button aria-label="Submit form">Submit</button>
```

---

### Task 11.13: `html-aria-level-must-be-valid`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** `aria-level` attribute must have a valid integer value (1-6 for headings).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div role="heading" aria-level="0">
<div role="heading" aria-level="7">
<div role="heading" aria-level="abc">

<!-- Good -->
<div role="heading" aria-level="2">
```

---

### Task 11.14: `html-aria-role-heading-requires-level`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Elements with `role="heading"` must have an `aria-level` attribute.

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div role="heading">Title</div>

<!-- Good -->
<div role="heading" aria-level="2">Title</div>
```

---

### Task 11.15: `html-aria-role-must-be-valid`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** `role` attribute must contain a valid WAI-ARIA role.

**Complexity:** Medium (requires list of valid ARIA roles)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<div role="invalid-role">
<div role="">

<!-- Good -->
<div role="button">
<div role="navigation">
```

---

### Task 11.16: `html-no-aria-hidden-on-focusable`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow `aria-hidden="true"` on focusable elements.

**Complexity:** Medium (requires knowledge of focusable elements)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button aria-hidden="true">Click</button>
<a href="/page" aria-hidden="true">Link</a>

<!-- Good -->
<div aria-hidden="true">Decorative</div>
<button>Click</button>
```

---

## Batch 4: Accessibility Rules - Other (4 rules)

### Task 11.17: `html-avoid-both-disabled-and-aria-disabled`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow using both `disabled` and `aria-disabled` on the same element (redundant and potentially confusing).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button disabled aria-disabled="true">Submit</button>

<!-- Good -->
<button disabled>Submit</button>
<button aria-disabled="true">Submit</button>
```

---

### Task 11.18: `html-input-require-autocomplete`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require `autocomplete` attribute on input elements that accept text input.

**Complexity:** Medium (requires knowledge of input types that accept text)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<input type="text" name="email">

<!-- Good -->
<input type="text" name="email" autocomplete="email">
<input type="checkbox" name="agree">
```

---

### Task 11.19: `html-navigation-has-label`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** `<nav>` elements should have an accessible label (`aria-label` or `aria-labelledby`).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<nav>
  <a href="/">Home</a>
</nav>

<!-- Good -->
<nav aria-label="Main navigation">
  <a href="/">Home</a>
</nav>
```

---

### Task 11.20: `html-no-empty-headings`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Heading elements (`<h1>`-`<h6>`) must not be empty.

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<h1></h1>
<h2>   </h2>

<!-- Good -->
<h1>Page Title</h1>
```

---

## Batch 5: Document Structure Rules (3 rules)

### Task 11.21: `html-body-only-elements`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Certain elements (e.g., `<div>`, `<p>`, `<main>`) should only appear inside `<body>`.

**Complexity:** High (requires knowledge of element categories and document structure)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<head>
  <div>Content in head</div>
</head>

<!-- Good -->
<body>
  <div>Content in body</div>
</body>
```

---

### Task 11.22: `html-head-only-elements`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Certain elements (e.g., `<title>`, `<meta>`, `<link>`) should only appear inside `<head>`.

**Complexity:** High (requires knowledge of element categories and document structure)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<body>
  <title>Page Title</title>
</body>

<!-- Good -->
<head>
  <title>Page Title</title>
</head>
```

---

### Task 11.23: `html-no-block-inside-inline`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Disallow block-level elements nested inside inline elements.

**Complexity:** High (requires knowledge of block vs inline element categories)

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<span><div>Block in inline</div></span>
<a href="/"><p>Paragraph in anchor</p></a>

<!-- Good -->
<div><span>Inline in block</span></div>
```

---

## Summary

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 5 | Attribute rules |
| Batch 2 | 5 | Element structure rules |
| Batch 3 | 6 | ARIA accessibility rules |
| Batch 4 | 4 | Other accessibility rules |
| Batch 5 | 3 | Document structure rules |

**Total: 23 rules**

After completing this phase:
- HTML rules: 31/31 implemented

## Verification

For each rule:
1. `cd herb-lint && ./bin/rspec` - All tests pass
2. `cd herb-lint && ./bin/steep check` - Type checking passes
3. Manual test with sample ERB files

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - Rule list and architecture
- [Phase 8: Rule Expansion](./phase-8-rule-expansion.md) - Previous rule expansion phase
