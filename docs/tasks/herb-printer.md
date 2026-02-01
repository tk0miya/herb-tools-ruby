# herb-printer gem Implementation

## Overview

Implementation of the herb-printer gem providing AST-to-source-code printer infrastructure. The primary deliverable is `IdentityPrinter`, which performs lossless round-trip reconstruction from Herb AST.

**Design document:** [printer-design.md](../design/printer-design.md)

**Reference:** TypeScript `@herb-tools/printer` package

**Task count:** 12

---

## Task 1: Create Gem Skeleton

### Implementation

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

## Task 2: Add herb-printer to CI

### Implementation

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

## Task 3: Implement PrintContext

### Implementation

- [ ] Create `lib/herb/printer/print_context.rb`
  - [ ] `initialize` — initialize `@output`, `@indent_level`, `@current_column`, `@tag_stack`
  - [ ] `write(text)` — append text to output buffer
  - [ ] `write_with_column_tracking(text)` — append text and update column position across newlines
  - [ ] `indent` / `dedent` — increment/decrement indent level
  - [ ] `enter_tag(tag_name)` / `exit_tag` — push/pop tag stack
  - [ ] `at_start_of_line?` — check if cursor is at column 0
  - [ ] `current_indent_level` / `current_column` / `tag_stack` — accessors
  - [ ] `get_output` — return accumulated output string
  - [ ] `reset` — clear all state
- [ ] Add `require_relative` to `lib/herb/printer.rb`

### Verification

- [ ] Create `spec/herb/printer/print_context_spec.rb`
  - [ ] Test `write` appends text
  - [ ] Test `get_output` returns accumulated text
  - [ ] Test `reset` clears all state
  - [ ] Test `indent`/`dedent` track indent level
  - [ ] Test `write_with_column_tracking` tracks column across newlines
  - [ ] Test `enter_tag`/`exit_tag` maintain tag stack
  - [ ] Test `at_start_of_line?` reflects column position

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/print_context_spec.rb
```

---

## Task 4: Implement Base Printer

### Implementation

- [ ] Create `lib/herb/printer/base.rb`
  - [ ] Inherit from `Herb::Visitor`
  - [ ] `initialize` — create `@context` (`PrintContext`)
  - [ ] `self.print(input, ignore_errors:)` — class-level convenience method
  - [ ] `print(input, ignore_errors:)` — instance method with input type dispatch
    - [ ] `nil` → return `""`
    - [ ] `Token` → return `token.value`
    - [ ] `ParseResult` → extract root node, validate, visit
    - [ ] `Node` → validate, reset context, visit, return output
    - [ ] `Array` → reset context, visit each, return output
  - [ ] `write(text)` — private helper delegating to `@context.write`
  - [ ] `validate_no_errors!(node)` — raise `PrintError` if `node.recursive_errors` is non-empty
- [ ] Create `lib/herb/printer/print_error.rb`
  - [ ] Define `Herb::Printer::PrintError < StandardError`
- [ ] Add `require_relative` entries to `lib/herb/printer.rb`

### Verification

- [ ] Create `spec/herb/printer/base_spec.rb`
  - [ ] Test `nil` input returns `""`
  - [ ] Test `Token` input returns `token.value`
  - [ ] Test `ParseResult` input extracts and visits root node
  - [ ] Test `Node` input visits the node
  - [ ] Test `Array` input visits each node
  - [ ] Test `PrintError` raised when AST has errors and `ignore_errors: false`
  - [ ] Test no error raised when `ignore_errors: true`
  - [ ] Test bare `Base` subclass (no overrides) produces empty output

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/base_spec.rb
```

---

## Task 5: IdentityPrinter — HTML Leaf Nodes

### Implementation

- [ ] Create `lib/herb/printer/identity_printer.rb`
  - [ ] Inherit from `Herb::Printer::Base`
  - [ ] `visit_document_node` — `visit_all(node.children)`
  - [ ] `visit_literal_node` — `write(node.content)`
  - [ ] `visit_html_text_node` — `write(node.content)`
  - [ ] `visit_whitespace_node` — `write(node.value.value)` if value present
- [ ] Add `require_relative` to `lib/herb/printer.rb`

### Verification

- [ ] Create `spec/herb/printer/identity_printer_spec.rb`
  - [ ] Round-trip test: `"Hello, world!"`
  - [ ] Round-trip test: `"  \n  "` (whitespace only)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

## Task 6: IdentityPrinter — HTML Structure Nodes

### Implementation

- [ ] `visit_html_open_tag_node` — write `tag_opening` + `tag_name`, visit children, write `tag_closing`
- [ ] `visit_html_close_tag_node` — write `tag_opening`, split children around `tag_name` token, write `tag_closing`
- [ ] `visit_html_element_node` — enter tag context, visit `open_tag` + `body` + `close_tag`, exit tag context
- [ ] `split_children_around_token` — private helper using location-based comparison

### Verification

- [ ] Round-trip test: `<div></div>`
- [ ] Round-trip test: `<div>Hello</div>`
- [ ] Round-trip test: `<br>` (void element)
- [ ] Round-trip test: `<img src="photo.jpg">` (void with attribute)

```bash
cd herb-printer && ./bin/rspec spec/herb/printer/identity_printer_spec.rb
```

---

## Task 7: IdentityPrinter — HTML Attribute Nodes

### Implementation

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

## Task 8: IdentityPrinter — HTML Comment, Doctype, XML, CDATA

### Implementation

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

## Task 9: IdentityPrinter — ERB Leaf Nodes

### Implementation

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

## Task 10: IdentityPrinter — ERB Control Flow (Basic)

### Implementation

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

## Task 11: IdentityPrinter — ERB Control Flow (Loop/Case)

### Implementation

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

## Task 12: IdentityPrinter — ERB Begin/Rescue/Ensure

### Implementation

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

- [ ] All tasks (1–12) completed
- [ ] CI passes for herb-printer (spec, rubocop, steep)
- [ ] `./bin/rspec` passes all tests
- [ ] `gem build herb-printer.gemspec` succeeds
- [ ] Round-trip property holds: `IdentityPrinter.print(Herb.parse(source)) == source` for all test cases
