# frozen_string_literal: true

# This file serves as a reference marker for the herb-disable-comment-unnecessary rule.
#
# Unlike other rules, herb-disable-comment-unnecessary is NOT implemented as a separate
# rule class. Instead, it is integrated at the Linter level via UnnecessaryDirectiveDetector.
#
# **Why this design?**
#
# This rule requires knowledge of which offenses were actually suppressed by herb:disable
# comments. This information is only available after:
# 1. All rules have run and collected offenses
# 2. Directives have filtered which offenses are suppressed
#
# Therefore, detection happens in Linter#build_lint_result, not as a standard rule.
#
# **Note:** Both TypeScript and Ruby implementations use this same architectural approach.
# TypeScript integrates via checkForUnnecessaryDirectives() in the linter flow.
#
# **Implementation Location:**
# - Detection logic: lib/herb/lint/unnecessary_directive_detector.rb
# - Integration point: lib/herb/lint/linter.rb (build_lint_result method)
# - Test coverage: spec/herb/lint/unnecessary_directive_detector_spec.rb
#
# **For more details, see:**
# - docs/design/herb-lint-rules.md (Special Implementation Note section)
# - docs/tasks/phase-24-typescript-alignment.md (Task 24.1)
