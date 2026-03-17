# Phase 27: New herb-lint Rules (v0.9.0 additions)

Port the 23 new rules added in TypeScript v0.9.0 to the Ruby implementation.

**Status**: Not Started
**Priority**: Medium
**Dependencies**: Phase 26 complete (specifically Task 26.3 for new AST node support)

## Overview

TypeScript v0.9.0 added 23 new rules. Port these to Ruby to maintain feature parity.

Each task involves:
1. Implement the rule class in Ruby, referencing the TypeScript implementation
2. Register the rule in RuleRegistry
3. Write specs
4. Confirm the rule is configurable via `.herb.yml`

TypeScript source reference: `vendor/herb-upstream/javascript/packages/linter/src/rules/`

---

## Implementation Checklist

### ERB Rules — Conditional HTML Elements

#### Task 27.1: `erb-no-conditional-html-element` (severity: error)

Disallows conditional HTML elements where both the open and close tags are wrapped
in separate ERB conditionals. Targets `HTMLConditionalElementNode` (requires Task 26.3).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_conditional_html_element.rb`
- [ ] Implement referencing TypeScript `erb-no-conditional-html-element.ts`
- [ ] Detect offenses in `visit_html_conditional_element_node`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.2: `erb-no-conditional-open-tag` (severity: error)

Disallows conditional open tags (e.g. `<% if %><div><% end %>`).
Targets `HTMLConditionalOpenTagNode` (requires Task 26.3).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_conditional_open_tag.rb`
- [ ] Implement referencing TypeScript `erb-no-conditional-open-tag.ts`
- [ ] Detect offenses in `visit_html_conditional_open_tag_node`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.3: `erb-no-duplicate-branch-elements` (severity: warning, with autofix)

Warns when the same HTML element is repeated in every branch of a conditional.
Provides an autofix to hoist the element outside the conditional.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_duplicate_branch_elements.rb`
- [ ] Implement referencing TypeScript `erb-no-duplicate-branch-elements.ts`
- [ ] Implement autofix logic
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs (including autofix tests)
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.4: `erb-no-inline-case-conditions` (severity: warning)

Disallows writing `case`/`when`/`in` in the same ERB tag.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_inline_case_conditions.rb`
- [ ] Implement referencing TypeScript `erb-no-inline-case-conditions.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.5: `erb-no-then-in-control-flow` (severity: warning)

Disallows use of the `then` keyword in `if`/`unless` conditions.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_then_in_control_flow.rb`
- [ ] Implement referencing TypeScript `erb-no-then-in-control-flow.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### ERB Rules — Attribute and Output

#### Task 27.6: `erb-no-output-in-attribute-name` (severity: error)

Disallows using an ERB output tag (`<%= %>`) in the attribute name position.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_output_in_attribute_name.rb`
- [ ] Implement referencing TypeScript `erb-no-output-in-attribute-name.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.7: `erb-no-output-in-attribute-position` (severity: error)

Disallows using an ERB output tag in attribute position (outside an attribute value).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_output_in_attribute_position.rb`
- [ ] Implement referencing TypeScript `erb-no-output-in-attribute-position.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.8: `erb-no-raw-output-in-attribute-value` (severity: error)

Disallows using `html_safe` or `raw` inside attribute values.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_raw_output_in_attribute_value.rb`
- [ ] Implement referencing TypeScript `erb-no-raw-output-in-attribute-value.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.9: `erb-no-trailing-whitespace` (severity: error)

Disallows trailing whitespace inside ERB tags.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_trailing_whitespace.rb`
- [ ] Implement referencing TypeScript `erb-no-trailing-whitespace.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.10: `erb-no-interpolated-class-names` (severity: warning)

Disallows dynamic class name generation via ERB interpolation in `class` attributes.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_interpolated_class_names.rb`
- [ ] Implement referencing TypeScript `erb-no-interpolated-class-names.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### ERB Rules — Security

#### Task 27.11: `erb-no-unsafe-raw` (severity: error)

Disallows use of `html_safe` or `raw` methods (XSS prevention).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_unsafe_raw.rb`
- [ ] Implement referencing TypeScript `erb-no-unsafe-raw.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.12: `erb-no-unsafe-js-attribute` (severity: error)

Disallows ERB output in JavaScript event attributes (e.g. `onclick`).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_unsafe_js_attribute.rb`
- [ ] Implement referencing TypeScript `erb-no-unsafe-js-attribute.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.13: `erb-no-unsafe-script-interpolation` (severity: error)

Disallows unsafe ERB interpolation inside `<script>` tags.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_unsafe_script_interpolation.rb`
- [ ] Implement referencing TypeScript `erb-no-unsafe-script-interpolation.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.14: `erb-no-statement-in-script` (severity: warning)

Disallows ERB statement tags (`<% %>`) inside `<script>` tags.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_statement_in_script.rb`
- [ ] Implement referencing TypeScript `erb-no-statement-in-script.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### ERB Rules — Partials and Helpers

#### Task 27.15: `erb-no-instance-variables-in-partials` (severity: error)

Disallows instance variables (`@foo`) inside partial templates.

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_instance_variables_in_partials.rb`
- [ ] Implement referencing TypeScript `erb-no-instance-variables-in-partials.ts`
- [ ] Implement partial file detection (files whose names start with `_`)
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.16: `erb-no-javascript-tag-helper` (severity: warning)

Disallows use of the `javascript_tag` helper (use `content_tag(:script)` or a
plain `<script>` tag instead).

- [ ] Create `herb-lint/lib/herb/lint/rules/erb/no_javascript_tag_helper.rb`
- [ ] Implement referencing TypeScript `erb-no-javascript-tag-helper.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.17: `actionview-no-silent-helper` (severity: error)

Warns when an Action View helper (e.g. `link_to`) is called via a silent tag
(`<% %>`) instead of an output tag (`<%= %>`).

- [ ] Create `herb-lint/lib/herb/lint/rules/actionview/no_silent_helper.rb`
  (follow TypeScript's `actionview` category)
- [ ] Implement referencing TypeScript `actionview-no-silent-helper.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### HTML Rules

#### Task 27.18: `html-allowed-script-type` (severity: error)

Disallows `type` attribute values on `<script>` tags that are not in the allowed
list (e.g. `type="module"` and `type="text/javascript"` are allowed).

- [ ] Create `herb-lint/lib/herb/lint/rules/html/allowed_script_type.rb`
- [ ] Implement referencing TypeScript `html-allowed-script-type.ts`
- [ ] Extract the `allowedTypes` allowlist from the TypeScript implementation
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.19: `html-details-has-summary` (severity: warning)

Requires `<details>` elements to have a `<summary>` child element.

- [ ] Create `herb-lint/lib/herb/lint/rules/html/details_has_summary.rb`
- [ ] Implement referencing TypeScript `html-details-has-summary.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.20: `html-no-abstract-roles` (severity: warning)

Disallows abstract ARIA roles (e.g. `command`, `composite`, `input`).

- [ ] Create `herb-lint/lib/herb/lint/rules/html/no_abstract_roles.rb`
- [ ] Implement referencing TypeScript `html-no-abstract-roles.ts`
- [ ] Extract the list of abstract roles from the TypeScript implementation
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.21: `html-no-aria-hidden-on-body` (severity: warning)

Disallows `aria-hidden` attribute on the `<body>` element.

- [ ] Create `herb-lint/lib/herb/lint/rules/html/no_aria_hidden_on_body.rb`
- [ ] Implement referencing TypeScript `html-no-aria-hidden-on-body.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

#### Task 27.22: `html-require-closing-tags` (severity: error)

Requires explicit closing tags for elements where they are optional (e.g. `<p>`,
`<li>`, `<td>`). Targets `HTMLOmittedCloseTagNode` (requires Task 26.3).

- [ ] Create `herb-lint/lib/herb/lint/rules/html/require_closing_tags.rb`
- [ ] Implement referencing TypeScript `html-require-closing-tags.ts`
- [ ] Detect offenses in `visit_html_omitted_close_tag_node`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes

---

### Turbo Rules

#### Task 27.23: `turbo-permanent-require-id` (severity: error)

Requires elements with `data-turbo-permanent` to also have an `id` attribute
(`data-turbo-permanent` does not work without one).

- [ ] Create `herb-lint/lib/herb/lint/rules/turbo/permanent_require_id.rb`
  (use a `turbo/` subdirectory to follow the TypeScript category)
- [ ] Implement referencing TypeScript `turbo-permanent-require-id.ts`
- [ ] Add require to `herb-lint/lib/herb/lint.rb`
- [ ] Register in RuleRegistry
- [ ] Write specs
- [ ] Verify `(cd herb-lint && ./bin/rspec)` passes
