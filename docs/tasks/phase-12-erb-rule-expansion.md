# Phase 12: ERB Rule Expansion

This phase implements the remaining 12 ERB rules from the TypeScript reference implementation.
`erb-comment-syntax` is covered in Phase 8 (Task 8.6).

## Current Status

| Category | Spec | Implemented | Remaining |
|----------|------|-------------|-----------|
| ERB rules | 13 | 0 | 13 |

**Covered elsewhere:**
- `erb-comment-syntax` (Phase 8, Task 8.6)

## Task Organization

Rules are grouped by theme:
- **Batch 1:** Tag spacing and whitespace rules (simple, fixable)
- **Batch 2:** Control flow and output rules (medium complexity)
- **Batch 3:** Convention and strict locals rules (medium complexity)

---

## Batch 1: Tag Spacing & Whitespace Rules (4 rules)

### Task 12.1: `erb-no-empty-tags`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow empty ERB tags (`<% %>` with no content).

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<% %>
<%= %>

<!-- Good -->
<% do_something %>
<%= value %>
```

---

### Task 12.2: `erb-no-extra-newline`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Disallow more than 2 consecutive blank lines in ERB files.

**Complexity:** Low

**Fixable:** Yes

**Implementation Details:**
- Detect sequences of 4 or more consecutive newlines (`/\n{4,}/g`)
- Maximum allowed: 2 consecutive blank lines (3 newline characters)
- Apply to entire file, not just inside ERB tags

**Example:**
```erb
<!-- Bad: 3 blank lines (4 newlines) -->
<div>First</div>




<div>Second</div>

<!-- Good: Maximum 2 blank lines allowed -->
<div>First</div>


<div>Second</div>

<!-- Good: No blank lines -->
<div>First</div>
<div>Second</div>
```

---

### Task 12.3: `erb-no-extra-whitespace-inside-tags`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow extra whitespace inside ERB tag delimiters.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<%  value  %>
<%=  value  %>

<!-- Good -->
<% value %>
<%= value %>
```

---

### Task 12.4: `erb-require-whitespace-inside-tags`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require whitespace between ERB tag delimiters and content.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<%value%>
<%=value%>

<!-- Good -->
<% value %>
<%= value %>
```

---

## Batch 2: Control Flow & Output Rules (4 rules)

### Task 12.5: `erb-no-case-node-children`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow direct children inside `case` ERB blocks (content should be in `when`/`else` branches).

**Complexity:** Medium

**Fixable:** No

**Example:**
```erb
<!-- Bad -->
<% case value %>
  <p>Direct content</p>
<% when :a %>
  <p>A</p>
<% end %>

<!-- Good -->
<% case value %>
<% when :a %>
  <p>A</p>
<% else %>
  <p>Default</p>
<% end %>
```

---

### Task 12.6: `erb-no-output-control-flow`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Disallow control flow statements in ERB output tags (`<%= %>`).

**Complexity:** Medium

**Fixable:** No

**Example:**
```erb
<!-- Bad -->
<%= if condition %>
<%= case value %>

<!-- Good -->
<% if condition %>
<% case value %>
```

---

### Task 12.7: `erb-no-silent-tag-in-attribute-name`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Disallow ERB silent tags (`<%`, `<%-`, `<%#`) **within** HTML attribute names. Silent tags do not output content and cannot form part of an attribute name. This rule does not prevent using silent tags for conditional attribute logic in the attribute list.

**Severity:** `error`

**Enabled by default:** `true`

**Complexity:** Medium

**Fixable:** No

**Example:**
```erb
<!-- Bad: Silent tag within attribute name -->
<div data-<% key %>-target="value"></div>
<div prefix-<%- variable -%>-suffix="test"></div>
<span id-<%# comment %>-name="test"></span>

<!-- Good: Output tag in attribute name -->
<div data-<%= key %>-target="value"></div>

<!-- Good: Output tag for entire attributes -->
<div <%= data_attributes_for(user) %>></div>

<!-- Good: Silent tags for conditional attributes (not in names) -->
<div <% if valid? %>data-valid="true"<% else %>data-valid="false"<% end %>></div>
<span <% if user.admin? %>class="admin"<% end %>></span>
```

---

### Task 12.8: `erb-right-trim`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Enforce consistent use of right-trim marker (`-%>` vs `%>`).

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad (when configured to require trim) -->
<% value %>

<!-- Good -->
<% value -%>
```

---

## Batch 3: Convention & Strict Locals Rules (4 rules)

### Task 12.9: `erb-prefer-image-tag-helper`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Prefer Rails `image_tag` helper over raw `<img>` tags.

**Complexity:** Medium

**Fixable:** No

**Example:**
```erb
<!-- Bad -->
<img src="<%= asset_path('logo.png') %>">

<!-- Good -->
<%= image_tag 'logo.png' %>
```

---

### Task 12.10: `erb-require-trailing-newline`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require a trailing newline at the end of the file.

**Complexity:** Low

**Fixable:** Yes

**Example:**
```erb
<!-- Bad (no newline at EOF) -->
<div>content</div>
<!-- Good (newline at EOF) -->
<div>content</div>

```

---

### Task 12.11: `erb-strict-locals-comment-syntax`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Enforce correct syntax for the `strict_locals` magic comment.

**Complexity:** Medium

**Fixable:** Yes

**Example:**
```erb
<!-- Bad -->
<%# locals: (name) %>

<!-- Good -->
<%# locals: (name: String) %>
```

---

### Task 12.12: `erb-strict-locals-required`
- [x] Implement rule
- [x] Add tests
- [x] Update RuleRegistry

**Description:** Require a `strict_locals` magic comment in every partial.

**Complexity:** Medium

**Fixable:** No

**Example:**
```erb
<!-- Bad (missing strict_locals comment) -->
<div><%= name %></div>

<!-- Good -->
<%# locals: (name: String) %>
<div><%= name %></div>
```

---

## Summary

| Batch | Rules | Focus |
|-------|-------|-------|
| Batch 1 | 4 | Tag spacing & whitespace rules |
| Batch 2 | 4 | Control flow & output rules |
| Batch 3 | 4 | Convention & strict locals rules |

**Total: 12 rules**

After completing this phase (plus Phase 8 Task 8.6):
- ERB rules: 13/13 implemented

## Verification

For each rule:
1. `cd herb-lint && ./bin/rspec` - All tests pass
2. `cd herb-lint && ./bin/steep check` - Type checking passes
3. Manual test with sample ERB files

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - Rule list and architecture
- [Phase 8: Rule Expansion](./phase-8-rule-expansion.md) - First rule expansion phase (includes `erb-comment-syntax`)
