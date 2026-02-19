# Phase 22: Custom Rules

**Status:** ✅ Implemented

**Background:** The TypeScript reference implementation uses `.herb/rules/**/*.mjs`, auto-discovering rule files from a fixed directory (`CustomRuleLoader` class). The Ruby implementation replaces this with an explicit require-based system: users list names in `linter.custom_rules`, and each is passed to `Kernel#require` at startup. This removes the fixed-directory constraint—rules can come from gems, local files, or any path on `$LOAD_PATH`.

## Overview

The custom rules system allows users to extend herb-lint with additional rules by listing names (gem names or file paths) in `.herb.yml`. Each is passed to `Kernel#require`; newly defined rule subclasses are auto-registered via ObjectSpace.

| Feature | TypeScript | Ruby | Status |
|---------|-----------|------|--------|
| Extension mechanism | `.herb/rules/**/*.mjs` directory (auto-discover) | `linter.custom_rules` explicit require list | ✅ Implemented (Ruby-specific) |
| Configuration | Implicit (auto-discover directory) | Explicit (`.herb.yml` custom_rules list) | ✅ Implemented |
| Auto-registration | ✅ Automatic | ✅ Automatic (ObjectSpace) | ✅ Done |
| Dynamic loading | ✅ Dynamic import | ✅ `Kernel#require` | ✅ Done |
| Rule configuration | ✅ Same as built-in | ✅ Same as built-in | ✅ Done |
| Disable flag | ✅ `--no-custom-rules` | ✅ `--no-custom-rules` | ✅ Done |

## Prerequisites

- herb-config gem with LinterConfig
- herb-lint gem with RuleRegistry and Runner

---

## Task Checklist

- [x] Task 22.1: Implement Custom Rules System

**Progress: 1/1 tasks completed**

---

### Task 22.1: Implement Custom Rules System

**Goal:** Allow users to load additional lint rules via `.herb.yml` configuration.

**Configuration format:**

```yaml
# .herb.yml
linter:
  custom_rules:
    - herb-lint-rails       # gem name
    - ./lib/my_rules/no_data_attributes  # local file path
```

**Implementation (completed):**

#### herb-config changes

1. **`schema.json`** - Added `custom_rules` array property to `linter` section
2. **`defaults.rb`** - Added `"custom_rules" => []` to linter defaults
3. **`linter_config.rb`** - Added `custom_rules` method returning `Array[String]`

#### herb-lint changes

4. **`rule_registry.rb`** - Added `load_custom_rules(names)` method:
   - Uses ObjectSpace snapshot-diff to auto-discover newly defined rule subclasses
   - Calls `Kernel#require` for each name
   - Registers any new `VisitorRule`/`SourceRule` subclasses found after require

5. **`runner.rb`** - Wired `registry.load_custom_rules(config.custom_rules)` into `build_linter`; skips when `no_custom_rules:` is true

6. **`cli.rb`** - Added `--no-custom-rules` option setting `no_custom_rules: true` on Runner

#### How auto-registration works

```ruby
def load_custom_rules(names)
  return if names.empty?

  before = all_rule_subclasses              # snapshot before
  names.each { require _1 }                # require each name
  (all_rule_subclasses - before).each { register(_1) }  # register new rules
end

def all_rule_subclasses
  ObjectSpace.each_object(Class)
             .select { _1 < Rules::VisitorRule || _1 < Rules::SourceRule }
             .to_a
end
```

Rule authors only need to define a class inheriting from `VisitorRule` or `SourceRule`. No explicit registration call is needed.

#### Example: gem-based custom rules

```ruby
# lib/herb_lint_rails.rb
require "herb/lint"

module HerbLintRails
  class PreferTurboFrame < Herb::Lint::Rules::VisitorRule
    def self.rule_name = "rails/prefer-turbo-frame"
    def self.description = "Prefer <turbo-frame> over manual Turbo Frame patterns"
    def self.safe_autofixable? = false
    def self.unsafe_autofixable? = false

    def visit_html_element(node)
      # Rule implementation
      super
    end
  end
end
```

#### Edge cases

| Case | Behavior |
|------|----------|
| require name not found | `LoadError` propagates to CLI |
| File defines no rule classes | Silently ignored (empty diff) |
| Overrides built-in rule name | Custom version wins (hash overwrite) |
| Duplicate names in list | `require` is idempotent, no double-registration |

**Verification:**

```bash
(cd herb-config && ./bin/rspec spec/herb/config/linter_config_spec.rb spec/herb/config/defaults_spec.rb)
(cd herb-lint && ./bin/rspec spec/herb/lint/rule_registry_spec.rb spec/herb/lint/runner_spec.rb spec/herb/lint/cli_spec.rb)
```

---

## Design Decision: Why Explicit require Instead of Directory Auto-Discovery

The core difference from TypeScript is **not** "gem vs file" — `Kernel#require` works with gem names, local paths, and any name on `$LOAD_PATH`. The real change is:

| | TypeScript | Ruby |
|--|--|--|
| Discovery | Auto-discover from fixed directory (`.herb/rules/**/*.mjs`) | Explicit list in `.herb.yml` (`linter.custom_rules`) |
| Loading | Dynamic import | `Kernel#require` |
| Source | Local files only | Gems, local files, any `$LOAD_PATH` entry |
| Disable | `--no-custom-rules` | `--no-custom-rules` |

Reasons for choosing explicit require:

1. **Explicit over implicit** - Listing in `.herb.yml` is transparent; no magic directory scanning
2. **No fixed-directory constraint** - Rules can live anywhere `require` can reach
3. **Bundler compatibility** - Gems are already on `$LOAD_PATH` via Bundler; no extra path setup needed
4. **Reusability** - Sharable as gems with their own versioning and test suites

This is a deliberate divergence from the TypeScript reference, documented as a Ruby-specific design choice.

## Reference

- TypeScript: `javascript/packages/linter/src/custom-rule-loader.ts`
- Ruby implementation: `herb-lint/lib/herb/lint/rule_registry.rb` (`load_custom_rules` method)
- Configuration: `herb-config/lib/herb/config/linter_config.rb` (`custom_rules` method)
