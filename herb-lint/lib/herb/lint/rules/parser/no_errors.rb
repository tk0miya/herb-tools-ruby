# frozen_string_literal: true

# This file serves as a reference marker for the parser-no-errors rule.
#
# Unlike other rules, parser-no-errors is NOT implemented as a standard rule class.
# Instead, it is integrated at the Linter level and handled specially.
#
# Description:
#   Report parser errors as linting offenses. This rule surfaces syntax errors, malformed HTML,
#   and other parsing issues that prevent the document from being correctly parsed.
#
# Good:
#   <h2>Welcome to our site</h2>
#   <p>This is a paragraph with proper structure.</p>
#
#   <div class="container">
#     <img src="image.jpg" alt="Description">
#   </div>
#
# Bad:
#   <h2>Welcome to our site</h3>
#
#   <div>
#     <p>This paragraph is never closed
#   </div>
#
#   Some content
#   </div>
#
# **Why this design?**
#
# Parser errors occur before the AST is available, making it impossible to run
# standard rule checks. The Linter needs to handle parse failures early in the
# pipeline, before normal rule execution begins.
#
# **Processing Flow:**
# 1. Linter calls Herb.parse(source)
# 2. If parse_result.failed?, Linter creates parser error offenses directly
# 3. Parser errors are reported with hardcoded rule_name "parser-no-errors" and severity "error"
# 4. Normal rule checking is skipped (no valid AST available)
#
# **NOTE:** Both TypeScript and Ruby implementations use this same architectural approach.
# TypeScript handles parser errors via the linter's error handling flow, not as a ParserRule.
#
# **Implementation Location:**
# - Integration point: lib/herb/lint/linter.rb (parse_error_result and parse_error_offense methods)
# - Rule metadata: Hardcoded in Linter (rule_name: "parser-no-errors", severity: "error")
# - Test coverage: spec/herb/lint/linter_spec.rb (parser error handling tests)
#
# **For more details, see:**
# - Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/parser-no-errors.ts
# - Documentation: https://herb-tools.dev/linter/rules/parser-no-errors
# - docs/design/herb-lint-rules.md (Special Rules section)
