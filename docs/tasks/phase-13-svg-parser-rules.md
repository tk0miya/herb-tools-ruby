# Phase 13: SVG & Parser Rules

This phase implements the remaining 2 rules from the TypeScript reference implementation: 1 SVG rule and 1 parser rule.

## Current Status

| Category | Spec | Implemented | Remaining |
|----------|------|-------------|-----------|
| SVG rules | 1 | 0 | 1 |
| Parser rules | 1 | 0 | 1 |

---

## Task 13.1: `svg-tag-name-capitalization`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Enforce correct capitalization of SVG element and attribute names. SVG uses camelCase for many elements (e.g., `clipPath`, `linearGradient`, `textPath`) unlike HTML which is case-insensitive.

**Complexity:** Medium (requires list of SVG elements and their correct capitalization)

**Fixable:** Yes

**Example:**
```html
<!-- Bad -->
<svg>
  <clippath id="clip">
    <rect width="100" height="100"/>
  </clippath>
  <lineargradient id="grad">
    <stop offset="0%" stop-color="red"/>
  </lineargradient>
</svg>

<!-- Good -->
<svg>
  <clipPath id="clip">
    <rect width="100" height="100"/>
  </clipPath>
  <linearGradient id="grad">
    <stop offset="0%" stop-color="red"/>
  </linearGradient>
</svg>
```

---

## Task 13.2: `parser-no-errors`
- [ ] Implement rule
- [ ] Add tests
- [ ] Update RuleRegistry

**Description:** Report parser errors as lint offenses. When the Herb parser encounters syntax errors in ERB templates, surface them as lint violations so users see all issues in one report.

**Complexity:** Low

**Fixable:** No

**Example:**
```erb
<!-- Bad (unclosed tag) -->
<div>
  <span>unclosed

<!-- Bad (malformed ERB) -->
<%= unclosed
```

---

## Summary

| Task | Rule | Category |
|------|------|----------|
| 13.1 | `svg-tag-name-capitalization` | SVG |
| 13.2 | `parser-no-errors` | Parser |

**Total: 2 rules**

After completing this phase:
- SVG rules: 1/1 implemented
- Parser rules: 1/1 implemented

## Verification

For each rule:
1. `cd herb-lint && ./bin/rspec` - All tests pass
2. `cd herb-lint && ./bin/steep check` - Type checking passes
3. Manual test with sample ERB files

## Related Documents

- [herb-lint Design](../design/herb-lint-design.md) - Rule list and architecture
