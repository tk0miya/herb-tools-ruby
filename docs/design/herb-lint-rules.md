# herb-lint Rules Design Document

This document describes the rule system design for herb-lint based on analysis of both the TypeScript (original) and Ruby implementations.

**Last Updated:** 2026-02-09
**Based On:** TypeScript v0.x, Ruby implementation (Phase 24)

---

## Overview

herb-lint implements a comprehensive rule system for validating ERB templates. The rule system consists of:

- **52 total rules** in TypeScript original
- **51 total rules** in Ruby implementation (98% complete)
- **5 categories**: ERB, HTML, Herb directives, SVG, Parser

---

## Rule Metadata Structure

Each rule has the following metadata:

### Rule Identity
- **name**: Kebab-case identifier (e.g., `html-img-require-alt`)
- **category**: One of `erb`, `html`, `herb`, `svg`, `parser`
- **description**: Human-readable explanation of what the rule checks

### Behavioral Properties
- **enabled_by_default**: Boolean (default: `true`)
- **default_severity**: One of `error`, `warning`, `info`, `hint`
- **safe_autofixable**: Boolean indicating if safe autofix is available
- **unsafe_autofixable**: Boolean indicating if unsafe autofix is available

### Implementation Details
- **rule_type**: Implementation approach
  - TypeScript: `ParserRule`, `SourceRule`, `LexerRule`
  - Ruby: `VisitorRule`, `SourceRule`, `DirectiveRule`, `Base`

---

## Rules Disabled by Default

**5 rules are disabled by default** in TypeScript (opt-in):

| Rule | Severity | Rationale |
|------|----------|-----------|
| `erb-strict-locals-required` | error | Rails 7+ opt-in feature, not universally applicable |
| `html-navigation-has-label` | error | High false positive rate, context-dependent |
| `html-no-block-inside-inline` | error | Complex CSS considerations, may be intentional |
| `html-no-space-in-tag` | error | Rare issue, low priority |
| `html-no-title-attribute` | error | Controversial (title has accessibility tradeoffs) |

### Design Rationale

Rules are disabled by default when:
1. They enforce opt-in framework features
2. They have high false positive rates
3. The violation is context-dependent and requires domain knowledge
4. The rule is controversial in the web standards community

---

## Severity Level Guidelines

### Error (default for most rules)
Used for violations that:
- Break HTML/ERB syntax
- Create accessibility barriers
- Violate web standards
- Likely cause runtime issues

**Examples:**
- `erb-comment-syntax` - Syntax errors
- `html-img-require-alt` - Accessibility requirement
- `html-no-duplicate-ids` - HTML standard violation

### Warning
Used for violations that:
- Are style preferences
- Have contextual exceptions
- Are best practices but not requirements

**Examples:**
- `html-attribute-double-quotes` - Style preference
- `erb-prefer-image-tag-helper` - Rails best practice
- `html-no-empty-attributes` - Code quality

### Info / Hint
Currently unused in herb-lint, reserved for:
- Educational suggestions
- Performance optimizations
- Code smell indicators

---

## Autofix Capabilities

### Safe Autofix (16 rules support this)

Changes that are **guaranteed to preserve behavior**:

**ERB Rules (5 rules):**
- `erb-comment-syntax` - Convert `<% # comment %>` to `<%# comment %>`
- `erb-no-extra-whitespace-inside-tags` - Normalize whitespace
- `erb-require-whitespace-inside-tags` - Add required whitespace
- `erb-right-trim` - Add right-trim `-%>` where needed
- `erb-require-trailing-newline` - Add/normalize trailing newline

**HTML Rules (10 rules):**
- `html-attribute-double-quotes` - Change single to double quotes
- `html-attribute-equals-spacing` - Remove spaces around `=`
- `html-attribute-values-require-quotes` - Add quotes to unquoted values
- `html-boolean-attributes-no-value` - Remove values from boolean attrs
- `html-no-self-closing` - Convert self-closing to proper void element syntax
- `html-no-space-in-tag` - Remove illegal spaces in tags
- `html-tag-name-lowercase` - Convert tag names to lowercase

**SVG Rules (1 rule):**
- `svg-tag-name-capitalization` - Fix SVG camelCase tag names

### Unsafe Autofix

Currently **no unsafe autofixes** are implemented. Unsafe fixes would be used for:
- Structural changes that might affect behavior
- Changes requiring semantic understanding
- Fixes with multiple valid approaches

### Non-Fixable Rules (34 rules)

Rules that **cannot be automatically fixed**:
- Require semantic understanding (e.g., `html-img-require-alt`)
- Need human judgment (e.g., `html-navigation-has-label`)
- Detect logical errors (e.g., `erb-no-output-control-flow`)
- Validate external references (e.g., `html-no-duplicate-ids`)

---

## Rule Categories

### ERB Rules (13 rules)

Rules specific to ERB syntax and Rails conventions.

**Syntax & Structure:**
- `erb-comment-syntax` - Enforce `<%#` comment syntax
- `erb-no-empty-tags` - Disallow empty ERB tags
- `erb-require-whitespace-inside-tags` - Require whitespace in tags
- `erb-no-extra-whitespace-inside-tags` - Disallow extra whitespace
- `erb-right-trim` - Enforce consistent right-trim usage

**Content Validation:**
- `erb-no-case-node-children` - Validate case statement structure
- `erb-no-output-control-flow` - Disallow control flow in output tags
- `erb-no-silent-tag-in-attribute-name` - No silent tags in attribute names

**File-Level:**
- `erb-no-extra-newline` - Control newlines between ERB blocks
- `erb-require-trailing-newline` - Require trailing newline

**Rails-Specific:**
- `erb-prefer-image-tag-helper` - Prefer `image_tag` over `<img>`
- `erb-strict-locals-comment-syntax` - Validate strict_locals syntax
- `erb-strict-locals-required` - Require strict_locals (disabled by default)

### HTML Rules (31 rules)

Rules for HTML syntax, structure, and accessibility.

**Attributes:**
- `html-attribute-double-quotes` - Prefer double quotes
- `html-attribute-equals-spacing` - No spaces around `=`
- `html-attribute-values-require-quotes` - Quote all values
- `html-boolean-attributes-no-value` - Boolean attrs without values
- `html-no-empty-attributes` - Disallow empty attribute values
- `html-no-underscores-in-attribute-names` - Use hyphens not underscores

**Structure:**
- `html-tag-name-lowercase` - Lowercase tag names
- `html-no-self-closing` - Proper void element syntax
- `html-no-space-in-tag` - No spaces in opening tags
- `html-no-nested-links` - No nested `<a>` tags
- `html-no-block-inside-inline` - No block in inline (disabled by default)
- `html-body-only-elements` - Body-only elements location
- `html-head-only-elements` - Head-only elements location

**Validation:**
- `html-no-duplicate-attributes` - No duplicate attributes on same element
- `html-no-duplicate-ids` - No duplicate id values in document
- `html-no-duplicate-meta-names` - No duplicate meta name attributes

**Accessibility (ARIA):**
- `html-img-require-alt` - Require alt on images
- `html-iframe-has-title` - Require title on iframes
- `html-anchor-require-href` - Require href on anchors
- `html-navigation-has-label` - Navigation landmarks need labels (disabled by default)
- `html-no-aria-hidden-on-focusable` - Don't hide focusable elements
- `html-no-positive-tab-index` - No positive tabindex values
- `html-aria-attribute-must-be-valid` - Valid ARIA attributes
- `html-aria-level-must-be-valid` - Valid ARIA level values
- `html-aria-label-is-well-formatted` - Well-formatted ARIA labels
- `html-aria-role-must-be-valid` - Valid ARIA roles
- `html-aria-role-heading-requires-level` - Heading roles need level

**Input Elements:**
- `html-input-require-autocomplete` - Require autocomplete on inputs
- `html-avoid-both-disabled-and-aria-disabled` - Don't use both disabled attributes

**Best Practices:**
- `html-no-empty-headings` - Headings must have content
- `html-no-title-attribute` - Avoid title attribute (disabled by default)

### Herb Directive Rules (6 rules)

Meta-rules that validate herb-lint directive comments.

- `herb-disable-comment-malformed` - Validate directive syntax
- `herb-disable-comment-missing-rules` - Require rule names
- `herb-disable-comment-valid-rule-name` - Validate rule names exist
- `herb-disable-comment-no-duplicate-rules` - No duplicate rules in directive
- `herb-disable-comment-no-redundant-all` - Don't use `all` with specific rules
- `herb-disable-comment-unnecessary` - Warn when directive suppresses nothing

**Special Implementation Note:**

The `herb-disable-comment-unnecessary` rule has a unique implementation in **both TypeScript and Ruby**. Unlike other rules that validate syntax alone, this rule requires knowledge of which offenses were actually suppressed by disable comments.

- **TypeScript**: Special integration at Linter level
  - Detection happens after offense filtering via `checkForUnnecessaryDirectives()`
  - Integrated into the main linting flow
  - See: `javascript/packages/linter/src/linter.ts`

- **Ruby**: Implemented via `UnnecessaryDirectiveDetector` at Linter level
  - Detection happens after all rules run and offenses are filtered
  - Integrated into `Linter#build_lint_result`
  - Respects rule configuration (enabled/disabled, severity)
  - See: `lib/herb/lint/unnecessary_directive_detector.rb`

Both implementations use the same architectural approach: integrating detection at the Linter level rather than as a standard rule, because this rule uniquely depends on the results of all other rules.

### SVG Rules (1 rule)

Rules for SVG-specific syntax.

- `svg-tag-name-capitalization` - Proper camelCase for SVG tags (e.g., `clipPath`)

### Parser Rules (1 rule)

Rules for parser-level errors.

- `parser-no-errors` - No parse errors in template

---

## Implementation Architecture

### Rule Types

Rules are implemented using different base classes depending on their needs:

**ParserRule** (Primary pattern - 48/52 rules)
- Operates on the parsed AST
- Most common pattern for HTML/ERB validation
- Direct access to node structure

**SourceRule** (3 rules)
- Operates on raw source text
- Used when AST doesn't preserve necessary information
- Examples: `erb-no-extra-newline`, `erb-require-trailing-newline`, `erb-strict-locals-required`

**LexerRule** (Unused)
- Would operate on token stream
- Reserved for future token-level rules

### Architectural Design Differences

The Ruby implementation introduces two architectural patterns that differ from the TypeScript original:

#### 1. VisitorRule Pattern

**TypeScript Approach:**
- Uses `ParserRule` with imperative traversal
- Rules manually walk the AST nodes
- More explicit control flow

**Ruby Approach:**
- Uses `VisitorRule` with visitor pattern
- Rules define `visit_*` methods for node types
- Framework handles traversal automatically
- Cleaner separation of concerns

**Design Rationale:**
- Visitor pattern is more idiomatic in Ruby
- Reduces boilerplate in rule implementations
- Better aligns with Ruby AST libraries (parser, rubocop)

#### 2. DirectiveRule Pattern

**TypeScript Approach:**
- Herb directive validation uses standard `ParserRule`
- Mixed with other rule logic

**Ruby Approach:**
- Introduces dedicated `DirectiveRule` base class
- Specialized for `herb:disable` comment validation
- 5 rules use this pattern: `herb-disable-comment-*`

**Design Rationale:**
- Clearer separation: directive meta-rules vs content rules
- Specialized API for directive parsing
- Easier to extend directive syntax in the future

**Example Usage:**
```ruby
class DisableCommentMalformed < DirectiveRule
  def validate_directive(comment, location)
    # Specialized directive validation logic
  end
end
```

These patterns represent **intentional design improvements** in the Ruby implementation while maintaining behavioral compatibility with TypeScript.

### Rule Implementation Pattern (TypeScript)

```typescript
export class RuleName extends ParserRule {
  static autocorrectable = true  // If autofix available
  name = "rule-name"

  get defaultConfig(): FullRuleConfig {
    return {
      enabled: true,      // or false for opt-in rules
      severity: "error"   // or "warning"
    }
  }

  check(result: ParseResult, context?: LintContext) {
    // Detection logic
  }

  autofix(offense: LintOffense, result: ParseResult) {
    // Fix logic (if autocorrectable)
  }
}
```

---

## References

- **TypeScript Implementation**: https://github.com/marcoroth/herb (JavaScript packages)
- **Ruby Implementation**: This repository (`herb-tools-ruby`)
- **HTML5 Specification**: https://html.spec.whatwg.org/
- **WCAG Guidelines**: https://www.w3.org/WAI/WCAG21/quickref/
- **WAI-ARIA Specification**: https://www.w3.org/TR/wai-aria/

---

## Appendix: Complete Rule List with Metadata

See [HERB_LINT_RULES_COMPLETE_ANALYSIS.md](../../HERB_LINT_RULES_COMPLETE_ANALYSIS.md) for the complete comparison table of all rules with full metadata.

### Quick Reference: Disabled by Default

```yaml
# These rules are disabled by default in TypeScript
# Consider your project needs before enabling
erb-strict-locals-required: off
html-navigation-has-label: off
html-no-block-inside-inline: off
html-no-space-in-tag: off
html-no-title-attribute: off
```

### Quick Reference: Autofix Support

**Safe autofix available (17 rules):**
- All ERB fixable rules (6)
- All HTML fixable rules (10)
- SVG capitalization (1)

Use `herb-lint --fix` to apply all safe fixes automatically.

---

**Document Version:** 1.0
**Maintained By:** herb-tools-ruby project
**Last Reviewed:** 2026-02-09
