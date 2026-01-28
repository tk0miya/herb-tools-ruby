# Phase 4: Rule Implementation

## Overview

Implementation of two actual lint rules: `A11y::AltText` (checks for alt attributes on img tags) and `Html::AttributeQuotes` (checks for quoted attribute values).

**Dependencies:** Phase 3 (herb-lint foundation) must be completed

**Task count:** 2

---

## Task 4.1: Implement A11y::AltText Rule

### Implementation

- [x] Create `lib/herb/lint/rules/a11y/alt_text.rb`
  - [x] Inherit from `VisitorRule`
  - [x] Set `rule_name` to `"alt-text"`
  - [x] Set `description` ("img tags should have alt attributes")
  - [x] Set `default_severity` to `"error"`
  - [x] Override `visit_html_element_node(node)`
    - [x] Check only when `node.tag_name == "img"`
    - [x] Check for presence of `alt` attribute
    - [x] Call `add_offense` if `alt` attribute is missing
    - [x] Call `super` to visit child nodes
- [x] Require in `lib/herb/lint.rb`
- [x] Create `spec/herb/lint/rules/a11y/alt_text_spec.rb`
  - [x] With alt attribute → no offense
  - [x] Without alt attribute → offense detected
  - [x] Empty alt attribute → no offense (empty is OK)
  - [x] Non-img element → no offense

### Implementation Hints

```ruby
def visit_html_element_node(node)
  if node.tag_name == "img"
    unless node.attributes.any? { |attr| attr.name == "alt" }
      add_offense(
        message: "img tag should have an alt attribute",
        location: node.location
      )
    end
  end
  super
end
```

### Test Fixture Examples

```erb
<!-- OK -->
<img src="photo.jpg" alt="A beautiful sunset">
<img src="logo.png" alt="">

<!-- NG -->
<img src="photo.jpg">
```

### Verification

```bash
bundle exec rspec spec/herb/lint/rules/a11y/alt_text_spec.rb
```

**Expected result:** All tests pass

---

## Task 4.2: Implement Html::AttributeQuotes Rule

### Implementation

- [ ] Create `lib/herb/lint/rules/html/attribute_quotes.rb`
  - [ ] Inherit from `VisitorRule`
  - [ ] Set `rule_name` to `"html/attribute-quotes"`
  - [ ] Set `description` ("Attribute values should be quoted")
  - [ ] Set `default_severity` to `"warning"`
  - [ ] Override `visit_html_attribute_node(node)`
    - [ ] Check only when attribute value exists
    - [ ] Check if attribute value is quoted
    - [ ] Call `add_offense` if not quoted
    - [ ] Call `super` to visit child nodes
- [ ] Require in `lib/herb/lint.rb`
- [ ] Create `spec/herb/lint/rules/html/attribute_quotes_spec.rb`
  - [ ] Double-quoted attribute → no offense
  - [ ] Single-quoted attribute → no offense
  - [ ] Unquoted attribute → offense detected
  - [ ] Boolean attribute (checked, etc.) → no offense

### Implementation Hints

```ruby
def visit_html_attribute_node(node)
  if node.value && !quoted?(node)
    add_offense(
      message: "Attribute value should be quoted",
      location: node.location
    )
  end
  super
end

private

def quoted?(node)
  # Check if node.value_quotation is '"' or "'"
  # Depends on Herb parser implementation, verify actual API
  node.value_quotation == '"' || node.value_quotation == "'"
end
```

### Test Fixture Examples

```erb
<!-- OK -->
<div class="container">
<input type='text'>
<input disabled>

<!-- NG -->
<div class=container>
<input type=text>
```

### Verification

```bash
bundle exec rspec spec/herb/lint/rules/html/attribute_quotes_spec.rb
```

**Expected result:** All tests pass

---

## Phase 4 Completion Criteria

- [ ] All tasks (4.1–4.2) completed
- [ ] Both rules work correctly
- [ ] `bundle exec rspec` passes all tests
- [ ] Manually verify that each rule can detect issues in actual ERB templates

---

## Next Phase

After Phase 4 is complete, proceed to [Phase 5: Linter & Runner Implementation](./phase-5-linter-runner.md).
