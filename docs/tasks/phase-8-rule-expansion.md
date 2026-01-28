# Phase 8: herb-lint Rule Expansion

This phase focuses on expanding herb-lint's rule coverage beyond the MVP's 3 rules.

## Current Status

| Category | Spec | Implemented | Remaining |
|----------|------|-------------|-----------|
| ERB rules | 13 | 0 | 13 |
| HTML rules | 25+ | 3 | 22+ |
| A11y rules | 15+ | 1 | 14+ |

**Implemented rules:**
- `a11y/alt-text`
- `html/attribute-quotes`
- `html/no-duplicate-attributes`
- `html/no-duplicate-id`

## Task Organization

Rules are prioritized by:
1. **Complexity**: Simple rules first to build momentum
2. **Fixable**: Fixable rules provide immediate user value
3. **Independence**: Rules without complex dependencies first

---

## Batch 1: Simple HTML Rules (4 rules)

### Task 8.1: `html/no-duplicate-attributes`
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

### Task 8.2: `html/lowercase-tags`
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

### Task 8.3: `html/lowercase-attributes`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Enforce lowercase attribute names.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<div CLASS="foo">

<!-- Good -->
<div class="foo">
```

---

### Task 8.4: `html/no-positive-tabindex`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

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

## Batch 2: Void Elements & Basic A11y (4 rules)

### Task 8.5: `html/void-element-style`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

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

### Task 8.6: `a11y/no-redundant-role`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Avoid redundant ARIA roles that match implicit semantics.

**Complexity:** Medium

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<button role="button">Click</button>
<a href="#" role="link">Link</a>

<!-- Good -->
<button>Click</button>
<a href="#">Link</a>
```

---

### Task 8.7: `a11y/iframe-has-title`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

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

### Task 8.8: `a11y/no-access-key`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Avoid accesskey attribute (accessibility issues with screen readers).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button accesskey="s">Save</button>

<!-- Good -->
<button>Save</button>
```

---

## Batch 3: HTML Document Structure (4 rules)

### Task 8.9: `html/button-type`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Require type attribute on button elements.

**Complexity:** Low

**Fixable:** Yes (add `type="button"`)

**Example:**
```html
<!-- Bad -->
<button>Click</button>

<!-- Good -->
<button type="button">Click</button>
<button type="submit">Submit</button>
```

---

### Task 8.10: `html/no-target-blank`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Warn about `target="_blank"` without `rel="noopener"` or `rel="noreferrer"`.

**Complexity:** Medium

**Fixable:** Yes (add `rel="noopener noreferrer"`)

**Example:**
```html
<!-- Bad -->
<a href="https://example.com" target="_blank">Link</a>

<!-- Good -->
<a href="https://example.com" target="_blank" rel="noopener noreferrer">Link</a>
```

---

### Task 8.11: `html/no-obsolete-tags`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Disallow obsolete HTML tags.

**Complexity:** Low

**Fixable:** No

**Obsolete tags:** `acronym`, `applet`, `basefont`, `big`, `blink`, `center`, `dir`, `font`, `frame`, `frameset`, `isindex`, `keygen`, `listing`, `marquee`, `menuitem`, `multicol`, `nextid`, `nobr`, `noembed`, `noframes`, `plaintext`, `spacer`, `strike`, `tt`, `xmp`

---

### Task 8.12: `html/no-inline-event-handlers`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Discourage inline event handlers (onclick, onmouseover, etc.).

**Complexity:** Low

**Fixable:** No

**Example:**
```html
<!-- Bad -->
<button onclick="handleClick()">Click</button>

<!-- Good (use unobtrusive JavaScript) -->
<button data-action="click">Click</button>
```

---

## Batch 4: ERB Rules - First Set (4 rules)

### Task 8.13: `erb/erb-tag-spacing`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Consistent spacing inside ERB tags.

**Complexity:** Medium

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<%=@user.name%>
<%   if @show   %>

<!-- Good -->
<%= @user.name %>
<% if @show %>
```

---

### Task 8.14: `erb/erb-no-trailing-whitespace`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** No trailing whitespace in ERB output.

**Complexity:** Low

**Fixable:** Yes

---

### Task 8.15: `erb/erb-comment-syntax`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

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

### Task 8.16: `erb/erb-simple-output`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Simplify unnecessary `.to_s` calls in ERB output.

**Complexity:** Medium

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<%= @user.name.to_s %>

<!-- Good -->
<%= @user.name %>
```

---

## Summary

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 4 | Simple HTML rules |
| Batch 2 | 4 | Void elements & A11y |
| Batch 3 | 4 | HTML document structure |
| Batch 4 | 4 | ERB rules (first set) |

**Total: 16 new rules**

After completing these batches:
- ERB rules: 4/13 implemented
- HTML rules: 10/25+ implemented
- A11y rules: 4/15+ implemented

## Verification

For each rule:
1. `cd herb-lint && ./bin/rspec` - All tests pass
2. `cd herb-lint && ./bin/steep check` - Type checking passes
3. Manual test with sample ERB files

## Related Documents

- [herb-lint Specification](../requirements/herb-lint.md) - Full rule list
- [herb-lint Design](../design/herb-lint-design.md) - Architecture
