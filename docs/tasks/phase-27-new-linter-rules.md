# Phase 27: herb-lint 新規ルール実装（v0.9.0 追加分）

herb 0.9.0 の TypeScript 実装で新規追加された 23 ルールを Ruby 版に移植する。

**Status**: Not Started
**Priority**: Medium
**Dependencies**: Phase 26 complete（特に Task 26.3 の新 AST ノード対応が必要）

## Overview

TypeScript v0.9.0 で 23 の新ルールが追加された。
これらを Ruby 版に移植してオリジナルとの互換性を保つ。

各タスクでは以下の作業を行う:
1. TypeScript の実装を参照して Ruby でルールクラスを実装
2. RuleRegistry への登録
3. スペックの作成
4. ルールが `.herb.yml` で設定可能であることを確認

TypeScript ソース参照先: `vendor/herb-upstream/javascript/packages/linter/src/rules/`

---

## Implementation Checklist

### ERB ルール（条件付き HTML 要素関連）

#### Task 27.1: `erb-no-conditional-html-element`（severity: error）

条件付き HTML 要素（`<% if %>` で囲まれた開きタグと閉じタグ）を禁止するルール。
`HTMLConditionalElementNode` を対象とする（Task 26.3 の完了が前提）。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_conditional_html_element.rb` を作成
- [ ] TypeScript 実装 `erb-no-conditional-html-element.ts` を参照して実装
- [ ] `visit_html_conditional_element_node` で違反を検出
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.2: `erb-no-conditional-open-tag`（severity: error）

条件付き開きタグ（`<% if %><div><% end %>`）を禁止するルール。
`HTMLConditionalOpenTagNode` を対象とする（Task 26.3 の完了が前提）。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_conditional_open_tag.rb` を作成
- [ ] TypeScript 実装 `erb-no-conditional-open-tag.ts` を参照して実装
- [ ] `visit_html_conditional_open_tag_node` で違反を検出
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.3: `erb-no-duplicate-branch-elements`（severity: warning、autofix 付き）

条件分岐の各ブランチで同じ HTML 要素が繰り返されている場合に警告するルール。autofix で重複を除去できる。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_duplicate_branch_elements.rb` を作成
- [ ] TypeScript 実装 `erb-no-duplicate-branch-elements.ts` を参照して実装
- [ ] autofix ロジックを実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成（autofix テストを含む）
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.4: `erb-no-inline-case-conditions`（severity: warning）

`case`/`when`/`in` を同一 ERB タグに記述することを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_inline_case_conditions.rb` を作成
- [ ] TypeScript 実装 `erb-no-inline-case-conditions.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.5: `erb-no-then-in-control-flow`（severity: warning）

`if`/`unless` 条件に `then` キーワードを使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_then_in_control_flow.rb` を作成
- [ ] TypeScript 実装 `erb-no-then-in-control-flow.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### ERB ルール（属性・出力関連）

#### Task 27.6: `erb-no-output-in-attribute-name`（severity: error）

属性名の位置に ERB 出力タグ（`<%= %>`）を使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_output_in_attribute_name.rb` を作成
- [ ] TypeScript 実装 `erb-no-output-in-attribute-name.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.7: `erb-no-output-in-attribute-position`（severity: error）

属性値の外側（属性位置）に ERB 出力タグを使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_output_in_attribute_position.rb` を作成
- [ ] TypeScript 実装 `erb-no-output-in-attribute-position.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.8: `erb-no-raw-output-in-attribute-value`（severity: error）

属性値内で `html_safe` や `raw` を使った出力を禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_raw_output_in_attribute_value.rb` を作成
- [ ] TypeScript 実装 `erb-no-raw-output-in-attribute-value.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.9: `erb-no-trailing-whitespace`（severity: error）

ERB タグ末尾の余分な空白を禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_trailing_whitespace.rb` を作成
- [ ] TypeScript 実装 `erb-no-trailing-whitespace.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.10: `erb-no-interpolated-class-names`（severity: warning）

`class` 属性値で ERB 補間によるクラス名の動的生成を禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_interpolated_class_names.rb` を作成
- [ ] TypeScript 実装 `erb-no-interpolated-class-names.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### ERB ルール（安全性関連）

#### Task 27.11: `erb-no-unsafe-raw`（severity: error）

`html_safe` や `raw` メソッドの使用を禁止するルール（XSS 防止）。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_unsafe_raw.rb` を作成
- [ ] TypeScript 実装 `erb-no-unsafe-raw.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.12: `erb-no-unsafe-js-attribute`（severity: error）

`onclick` 等の JavaScript イベント属性に ERB 出力を使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_unsafe_js_attribute.rb` を作成
- [ ] TypeScript 実装 `erb-no-unsafe-js-attribute.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.13: `erb-no-unsafe-script-interpolation`（severity: error）

`<script>` タグ内で安全でない ERB 補間を使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_unsafe_script_interpolation.rb` を作成
- [ ] TypeScript 実装 `erb-no-unsafe-script-interpolation.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.14: `erb-no-statement-in-script`（severity: warning）

`<script>` タグ内で ERB ステートメント（`<% %>`）を使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_statement_in_script.rb` を作成
- [ ] TypeScript 実装 `erb-no-statement-in-script.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### ERB ルール（パーシャル・ヘルパー関連）

#### Task 27.15: `erb-no-instance-variables-in-partials`（severity: error）

パーシャルテンプレート内でインスタンス変数（`@foo`）を使うことを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_instance_variables_in_partials.rb` を作成
- [ ] TypeScript 実装 `erb-no-instance-variables-in-partials.ts` を参照して実装
- [ ] パーシャルファイルの判定ロジックを実装（ファイル名が `_` で始まるもの）
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.16: `erb-no-javascript-tag-helper`（severity: warning）

`javascript_tag` ヘルパーの使用を禁止するルール（`content_tag(:script)` または `<script>` タグを使うべき）。

- [ ] `herb-lint/lib/herb/lint/rules/erb/no_javascript_tag_helper.rb` を作成
- [ ] TypeScript 実装 `erb-no-javascript-tag-helper.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.17: `actionview-no-silent-helper`（severity: error）

Action View ヘルパー（`link_to` 等）が出力タグ（`<%= %>`）ではなくサイレントタグ（`<% %>`）で呼び出されている場合に警告するルール。

- [ ] `herb-lint/lib/herb/lint/rules/erb/actionview_no_silent_helper.rb` を作成
  （または `herb-lint/lib/herb/lint/rules/actionview/no_silent_helper.rb` — TypeScript の分類に合わせる）
- [ ] TypeScript 実装 `actionview-no-silent-helper.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### HTML ルール

#### Task 27.18: `html-allowed-script-type`（severity: error）

`<script>` タグの `type` 属性に許可されていない値を使うことを禁止するルール。
`type="module"` や `type="text/javascript"` 等のみ許可。

- [ ] `herb-lint/lib/herb/lint/rules/html/allowed_script_type.rb` を作成
- [ ] TypeScript 実装 `html-allowed-script-type.ts` を参照して実装
- [ ] 許可リスト（`allowedTypes`）を TypeScript 実装から抽出
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.19: `html-details-has-summary`（severity: warning）

`<details>` 要素が `<summary>` 子要素を持つことを要求するルール。

- [ ] `herb-lint/lib/herb/lint/rules/html/details_has_summary.rb` を作成
- [ ] TypeScript 実装 `html-details-has-summary.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.20: `html-no-abstract-roles`（severity: warning）

抽象 ARIA ロール（`command`, `composite`, `input` 等）の使用を禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/html/no_abstract_roles.rb` を作成
- [ ] TypeScript 実装 `html-no-abstract-roles.ts` を参照して実装
- [ ] 抽象ロールの一覧を TypeScript 実装から抽出
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.21: `html-no-aria-hidden-on-body`（severity: warning）

`<body>` 要素に `aria-hidden` 属性を付けることを禁止するルール。

- [ ] `herb-lint/lib/herb/lint/rules/html/no_aria_hidden_on_body.rb` を作成
- [ ] TypeScript 実装 `html-no-aria-hidden-on-body.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

#### Task 27.22: `html-require-closing-tags`（severity: error）

省略可能な閉じタグ（`<p>`, `<li>`, `<td>` 等）を省略せず明示的に記述することを要求するルール。
`HTMLOmittedCloseTagNode` を対象とする（Task 26.3 の完了が前提）。

- [ ] `herb-lint/lib/herb/lint/rules/html/require_closing_tags.rb` を作成
- [ ] TypeScript 実装 `html-require-closing-tags.ts` を参照して実装
- [ ] `visit_html_omitted_close_tag_node` で違反を検出
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### Turbo ルール

#### Task 27.23: `turbo-permanent-require-id`（severity: error）

`data-turbo-permanent` 属性を持つ要素が `id` 属性も持つことを要求するルール
（Turbo の `data-turbo-permanent` は `id` がないと機能しないため）。

- [ ] `herb-lint/lib/herb/lint/rules/html/turbo_permanent_require_id.rb` を作成
  （または TypeScript の分類に合わせて `turbo/` サブディレクトリに配置）
- [ ] TypeScript 実装 `turbo-permanent-require-id.ts` を参照して実装
- [ ] `herb-lint/lib/herb/lint.rb` に require を追加
- [ ] RuleRegistry に登録
- [ ] スペックを作成
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認
