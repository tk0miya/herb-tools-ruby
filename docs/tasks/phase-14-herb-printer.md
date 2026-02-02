# Phase 14: herb-printer

Implementation of the herb-printer gem providing AST-to-source-code printer infrastructure. The primary deliverable is `IdentityPrinter`, which performs lossless round-trip reconstruction from Herb AST.

This phase is a prerequisite for [Phase 15: Autofix](./phase-15-autofix.md), which depends on `IdentityPrinter` to serialize modified AST back to source code.

**Design document:** [printer-design.md](../design/printer-design.md)

**Reference:** TypeScript `@herb-tools/printer` package

## Prerequisites

- Phase 1-7 (MVP) complete
- herb gem available

---

## Part A: Gem Setup

### Task 14.1: Create Gem Skeleton

**Status:** ✅

- [x] Run `bundle gem herb-printer --test=rspec --linter=rubocop`
- [x] Edit `herb-printer.gemspec` file
  - [x] Remove TODO comments
  - [x] Fill in `summary`, `description`, `homepage`
  - [x] Set `required_ruby_version` to `">= 3.3.0"`
  - [x] Add dependency: `spec.add_dependency "herb"`
- [x] Delete unnecessary files
  - [x] Delete `bin/console`
  - [x] Delete `bin/setup`
- [x] Create binstubs in `bin/` (copy from herb-core and adjust)
  - [x] `bin/rake`
  - [x] `bin/rbs`
  - [x] `bin/rbs-inline`
  - [x] `bin/rspec`
  - [x] `bin/rubocop`
  - [x] `bin/steep`
- [x] Create `lib/herb/printer.rb` entry point
  - [x] Define `Herb::Printer` module with `Error` base exception
- [x] Create `lib/herb/printer/version.rb`
  - [x] Define `Herb::Printer::VERSION = "0.1.0"`

### Verification

```bash
cd herb-printer
bundle install
./bin/rspec
```

**Expected result:** `0 examples, 0 failures`

---

### Task 14.2: Add herb-printer to CI

**Status:** ✅

- [x] Update `.github/workflows/ci.yml`
  - [x] Add herb-printer job (same structure as herb-core job)
- [x] Create `herb-printer/Steepfile`
  - [x] Configure target directories
  - [x] Configure library dependencies
- [x] Create `herb-printer/rbs_collection.yaml`
  - [x] Configure RBS collection dependencies

### Verification

```bash
cd herb-printer
./bin/rake
```

**Expected result:** CI passes for herb-printer (spec, rubocop, steep)

---

### Task 14.3: Implement PrintContext

**Status:** ✅

- [x] Create `lib/herb/printer/print_context.rb`
  - [x] `initialize` — initialize `@output`, `@indent_level`, `@current_column`, `@tag_stack`
  - [x] `write(text)` — append text to output buffer
  - [x] `write_with_column_tracking(text)` — append text and update column position across newlines
  - [x] `indent` / `dedent` — increment/decrement indent level
  - [x] `enter_tag(tag_name)` / `exit_tag` — push/pop tag stack
  - [x] `at_start_of_line?` — check if cursor is at column 0
  - [x] `current_indent_level` / `current_column` / `tag_stack` — accessors
  - [x] `get_output` — return accumulated output string
  - [x] `reset` — clear all state
- [x] Add `require_relative` to `lib/herb/printer.rb`

### Verification

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/print_context_spec.rb
```

---

## Part B: Base Printer & HTML Leaf Nodes

### Task 14.4: Implement Base Printer

- [x] Create `lib/herb/printer/base.rb`
  - [x] Inherit from `Herb::Visitor`
  - [x] `initialize` — create `@context` (`PrintContext`)
  - [x] `self.print(input, ignore_errors:)` — class-level convenience method
  - [x] `print(input, ignore_errors:)` — instance method with input type dispatch
    - [x] `nil` → return `""`
    - [x] `Token` → return `token.value`
    - [x] `ParseResult` → extract root node, validate, visit
    - [x] `Node` → validate, reset context, visit, return output
    - [x] `Array` → reset context, visit each, return output
  - [x] `write(text)` — private helper delegating to `@context.write`
  - [x] `validate_no_errors!(node)` — raise `PrintError` if `node.recursive_errors` is non-empty
- [x] Create `lib/herb/printer/print_error.rb`
  - [x] Define `Herb::Printer::PrintError < StandardError`
- [x] Add `require_relative` entries to `lib/herb/printer.rb`

### Verification

- [x] Create `spec/herb/printer/base_spec.rb`
  - [x] Test `nil` input returns `""`
  - [x] Test `Token` input returns `token.value`
  - [x] Test `ParseResult` input extracts and visits root node
  - [x] Test `Node` input visits the node
  - [x] Test `Array` input visits each node
  - [x] Test `PrintError` raised when AST has errors and `ignore_errors: false`
  - [x] Test no error raised when `ignore_errors: true`
  - [x] Test bare `Base` subclass (no overrides) produces empty output

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/base_spec.rb
```

---

### Task 14.5: IdentityPrinter — HTML Leaf Nodes

- [x] Create `lib/herb/printer/identity_printer.rb`
  - [x] Inherit from `Herb::Printer::Base`
  - [x] ~~`visit_document_node` — `visit_all(node.children)`~~ (not needed; default visitor handles traversal)
  - [x] `visit_literal_node` — `write(node.content)`
  - [x] `visit_html_text_node` — `write(node.content)`
  - [x] `visit_whitespace_node` — `write(node.value.value)` if value present
- [x] Add `require_relative` to `lib/herb/printer.rb`

### Verification

- [x] Create `spec/herb/printer/identity_printer_spec.rb`
  - [x] Round-trip test: `"Hello, world!"`
  - [x] Round-trip test: `"  \n  "` (whitespace only)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

## Part C: HTML Structure & Attributes

### Task 14.6: IdentityPrinter — HTML Structure Nodes

**Status:** ✅

- [x] `visit_html_open_tag_node` — write `tag_opening` + `tag_name`, visit children, write `tag_closing`
- [x] `visit_html_close_tag_node` — write `tag_opening`, split children around `tag_name` token, write `tag_closing`
- [x] `visit_html_element_node` — enter tag context, visit `open_tag` + `body` + `close_tag`, exit tag context
- [x] `split_children_around_token` — private helper using location-based comparison

### Verification

- [x] Round-trip test: `<div></div>`
- [x] Round-trip test: `<div>Hello</div>`
- [x] Round-trip test: `<br>` (void element)
- [x] Round-trip test: `<img src="photo.jpg">` (void with attribute — pending attribute visitors from Task 14.7)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

### Task 14.7: IdentityPrinter — HTML Attribute Nodes

- [ ] `visit_html_attribute_node` — visit `name`, write `equals` if present, visit `value` if present
- [ ] `visit_html_attribute_name_node` — `visit_child_nodes(node)`
- [ ] `visit_html_attribute_value_node` — write `open_quote` if quoted, visit children, write `close_quote` if quoted

### Verification

- [ ] Round-trip test: `<div class="container">text</div>`
- [ ] Round-trip test: `<div class='single-quoted'>text</div>`
- [ ] Round-trip test: `<input type="text" disabled>` (boolean attribute)
- [ ] Round-trip test: `<div id="main" class="wrapper" data-value="123">text</div>` (multiple attributes)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

### Task 14.8: IdentityPrinter — HTML Comment, Doctype, XML, CDATA

- [ ] `visit_html_comment_node` — write `comment_start`, visit children, write `comment_end`
- [ ] `visit_html_doctype_node` — write `tag_opening`, visit children, write `tag_closing`
- [ ] `visit_xml_declaration_node` — write `tag_opening`, visit children, write `tag_closing`
- [ ] `visit_cdata_node` — write `tag_opening`, visit children, write `tag_closing`

### Verification

- [ ] Round-trip test: `<!-- comment -->`
- [ ] Round-trip test: `<!-- multi\nline\ncomment -->`
- [ ] Round-trip test: `<!DOCTYPE html>`

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

## Part D: ERB Nodes

### Task 14.9: IdentityPrinter — ERB Leaf Nodes

- [ ] `print_erb_tag` — private helper: write `tag_opening` + `content` + `tag_closing`
- [ ] `visit_erb_content_node` — call `print_erb_tag`
- [ ] `visit_erb_end_node` — call `print_erb_tag`
- [ ] `visit_erb_yield_node` — call `print_erb_tag`

### Verification

- [ ] Round-trip test: `<%= user.name %>`
- [ ] Round-trip test: `<%# comment %>`
- [ ] Round-trip test: `<%= yield %>`
- [ ] Round-trip test: `<%- trimmed -%>` (trim markers)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

### Task 14.10: IdentityPrinter — ERB Control Flow (Basic)

- [ ] `visit_erb_block_node` — `print_erb_tag` + visit `body` + visit `end_node`
- [ ] `visit_erb_if_node` — `print_erb_tag` + visit `statements` + visit `subsequent` + visit `end_node`
- [ ] `visit_erb_else_node` — `print_erb_tag` + visit `statements`
- [ ] `visit_erb_unless_node` — `print_erb_tag` + visit `statements` + visit `else_clause` + visit `end_node`

### Verification

- [ ] Round-trip test: `<% items.each do |item| %><li><%= item %></li><% end %>`
- [ ] Round-trip test: `<% if condition %>yes<% end %>`
- [ ] Round-trip test: `<% if condition %>yes<% else %>no<% end %>`
- [ ] Round-trip test: `<% unless done %>work<% end %>`
- [ ] Round-trip test: nested `if`/`elsif`/`else`/`end`

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

### Task 14.11: IdentityPrinter — ERB Control Flow (Loop/Case)

- [ ] `visit_erb_while_node` — `print_erb_tag` + visit `statements` + visit `end_node`
- [ ] `visit_erb_until_node` — same pattern
- [ ] `visit_erb_for_node` — same pattern
- [ ] `visit_erb_case_node` — `print_erb_tag` + visit `children` + visit `conditions` + visit `else_clause` + visit `end_node`
- [ ] `visit_erb_case_match_node` — same pattern as case
- [ ] `visit_erb_when_node` — `print_erb_tag` + visit `statements`
- [ ] `visit_erb_in_node` — same pattern as when

### Verification

- [ ] Round-trip test: `<% while running %><%= status %><% end %>`
- [ ] Round-trip test: `<% until done %><%= progress %><% end %>`
- [ ] Round-trip test: `<% for item in list %><%= item %><% end %>`
- [ ] Round-trip test: `<% case x %><% when 1 %>one<% when 2 %>two<% else %>other<% end %>`

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

### Task 14.12: IdentityPrinter — ERB Begin/Rescue/Ensure

- [ ] `visit_erb_begin_node` — `print_erb_tag` + visit `statements` + visit `rescue_clause` + visit `else_clause` + visit `ensure_clause` + visit `end_node`
- [ ] `visit_erb_rescue_node` — `print_erb_tag` + visit `statements` + visit `subsequent`
- [ ] `visit_erb_ensure_node` — `print_erb_tag` + visit `statements`

### Verification

- [ ] Round-trip test: `<% begin %><%= risky %><% rescue %><%= fallback %><% end %>`
- [ ] Round-trip test: `<% begin %><%= x %><% rescue => e %><%= e %><% ensure %><%= cleanup %><% end %>`
- [ ] Round-trip test: chained rescue (`rescue A ... rescue B`)
- [ ] Comprehensive round-trip tests with mixed HTML+ERB templates

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

## Completion Criteria

- [ ] All tasks (14.1–14.12) completed
- [ ] CI passes for herb-printer (spec, rubocop, steep)
- [ ] `./bin/rspec` passes all tests
- [ ] `gem build herb-printer.gemspec` succeeds
- [ ] Round-trip property holds: `IdentityPrinter.print(Herb.parse(source)) == source` for all test cases

## Summary

| Task | Part | Description | Status |
|------|------|-------------|--------|
| 14.1 | A | Create gem skeleton | ✅ |
| 14.2 | A | Add herb-printer to CI | ✅ |
| 14.3 | A | Implement PrintContext | ✅ |
| 14.4 | B | Implement Base Printer | 📋 |
| 14.5 | B | IdentityPrinter — HTML Leaf Nodes | 📋 |
| 14.6 | C | IdentityPrinter — HTML Structure Nodes | ✅ |
| 14.7 | C | IdentityPrinter — HTML Attribute Nodes | 📋 |
| 14.8 | C | IdentityPrinter — HTML Comment, Doctype, XML, CDATA | 📋 |
| 14.9 | D | IdentityPrinter — ERB Leaf Nodes | 📋 |
| 14.10 | D | IdentityPrinter — ERB Control Flow (Basic) | 📋 |
| 14.11 | D | IdentityPrinter — ERB Control Flow (Loop/Case) | 📋 |
| 14.12 | D | IdentityPrinter — ERB Begin/Rescue/Ensure | 📋 |

**Total: 12 tasks** (4 complete, 8 remaining)

## Related Documents

- [Printer Design](../design/printer-design.md) — Architecture and detailed design
- [Autofix Design](../design/herb-lint-autofix-design.md) — Depends on IdentityPrinter
- [Phase 15: Autofix](./phase-15-autofix.md) — Next phase using IdentityPrinter
