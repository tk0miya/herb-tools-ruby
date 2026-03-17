# Phase 26: herb gem 0.9.0 互換性対応

herb gem が v0.8.9 から v0.9.0 に更新されたことによる破壊的変更への対応と、
既存コードのアップデートを行う。

**Status**: Not Started
**Priority**: High（破壊的変更を含むため最優先）
**Dependencies**: None

## Overview

herb 0.9.0 では AST フィールドのリネーム、`strict: true` のデフォルト化、
アクセシビリティルールの severity 変更、`html-anchor-require-href` ルールの拡張など、
Ruby 実装に直接影響する変更が複数ある。

## Implementation Checklist

### Task 26.1: `HTMLElementNode#source` → `#element_source` フィールドリネーム対応

herb 0.9.0 で `HTMLElementNode` の `source` フィールドが `element_source` に**リネーム**された（破壊的変更）。

**影響範囲の調査と修正:**
- [ ] `herb-core` の AST ノードヘルパーで `source` を参照している箇所を確認・修正
- [ ] `herb-printer` で `HTMLElementNode#source` を参照している箇所を確認・修正
- [ ] `herb-lint` で `HTMLElementNode#source` を参照している箇所を確認・修正
- [ ] `herb-format` で `HTMLElementNode#source` を参照している箇所を確認・修正
- [ ] 各 gem のテストで `HTMLElementNode#source` を使用している箇所を確認・修正
- [ ] 修正後に全 gem のテストスイートが通ることを確認

**検証方法:**
```bash
# source フィールドへの参照がないことを確認（element_source に移行済み）
grep -rn "\.source\b" herb-*/lib herb-*/spec 2>/dev/null | grep -v "element_source\|source_location\|source_line\|source_file\|source_path\|source_range\|source_rule\|source_code\|context\.source\|autofix.*source\|parse_result.*source"
```

---

### Task 26.2: `strict: true` デフォルト化への対応

herb 0.9.0 から `Herb.parse` のデフォルトが `strict: true` になった。
これにより `<p>` や `<li>` などの省略可能な閉じタグを持つ HTML を解析すると
`OmittedClosingTagError` が返るようになり、既存テストが壊れる可能性がある。

**調査:**
- [ ] `herb-lint` の `Herb.parse` 呼び出し箇所を全件確認（`herb-lint/lib/herb/lint/linter.rb` 等）
- [ ] `herb-format` の `Herb.parse` 呼び出し箇所を全件確認
- [ ] 全 gem のテストスイートを実行し、`OmittedClosingTagError` で壊れるテストを特定

**対応方針の選択（どちらかを採用）:**

オプション A: 既存の呼び出しに `strict: false` を明示して後方互換性を維持する
```ruby
Herb.parse(source, track_whitespace: true, strict: false)
```

オプション B: `strict: true` のデフォルトを受け入れ、テストを新しい挙動に合わせて更新する
（ユーザーが省略タグのあるテンプレートを扱う場合は `strict: false` をオプションで渡せるようにする）

- [ ] 採用するオプションを決定し、実装する
- [ ] 修正後に全 gem のテストスイートが通ることを確認

---

### Task 26.3: 新 AST ノード 7 種への Visitor 対応

herb 0.9.0 で以下の 7 ノードが新規追加された。
Visitor パターンを使う herb-printer・herb-lint が対応していないと `NoMethodError` が発生する。

| ノード名 | 説明 |
|---------|------|
| `HTMLConditionalOpenTagNode` | `<% if %>` で囲まれた条件付き開きタグ |
| `HTMLConditionalElementNode` | 条件付き HTML 要素全体 |
| `HTMLOmittedCloseTagNode` | 省略された閉じタグ（`<p>` 等） |
| `HTMLVirtualCloseTagNode` | 内部的に補完される仮想閉じタグ |
| `ERBOpenTagNode` | ERB 開きタグノード（Action View ヘルパー検出で導入） |
| `RubyLiteralNode` | Ruby リテラル |
| `RubyHTMLAttributesSplatNode` | `**attrs` スタイルの属性スプラット |

**herb-printer 対応:**
- [ ] `herb-printer/lib/herb/printer/identity_printer.rb` に 7 ノードの `visit_*` メソッドを追加
- [ ] 各ノードの子ノード構造を herb AST リファレンスで確認し、適切な子ノード訪問を実装
- [ ] `herb-printer` のテストスイートが通ることを確認

**herb-lint 対応:**
- [ ] `herb-lint/lib/herb/lint/rules/visitor_rule.rb` に 7 ノードのデフォルト訪問メソッドを追加（デフォルトは子ノードを再帰的に訪問）
- [ ] `herb-lint` のテストスイートが通ることを確認

**herb-core 対応（Visitor 基底クラスがあれば）:**
- [ ] `herb-core` に Visitor 基底クラスがある場合は同様に対応

---

### Task 26.4: アクセシビリティルール 14 個の severity 変更（error → warning）

TypeScript v0.9.0 でアクセシビリティ関連ルール 14 個の `defaultSeverity` が
`"error"` から `"warning"` に変更された。Ruby 実装でも合わせる。

**変更対象ルール（すべて `def self.default_severity = "error"` → `"warning"` に変更）:**

| ルール名 | Rubyファイル |
|---------|------------|
| `html-aria-attribute-must-be-valid` | `rules/html/aria_attribute_must_be_valid.rb` |
| `html-aria-label-is-well-formatted` | `rules/html/aria_label_is_well_formatted.rb` |
| `html-aria-level-must-be-valid` | `rules/html/aria_level_must_be_valid.rb` |
| `html-aria-role-heading-requires-level` | `rules/html/aria_role_heading_requires_level.rb` |
| `html-aria-role-must-be-valid` | `rules/html/aria_role_must_be_valid.rb` |
| `html-avoid-both-disabled-and-aria-disabled` | `rules/html/avoid_both_disabled_and_aria_disabled.rb` |
| `html-iframe-has-title` | `rules/html/iframe_has_title.rb` |
| `html-img-require-alt` | `rules/html/img_require_alt.rb` |
| `html-input-require-autocomplete` | `rules/html/input_require_autocomplete.rb` |
| `html-navigation-has-label` | `rules/html/navigation_has_label.rb` |
| `html-no-aria-hidden-on-focusable` | `rules/html/no_aria_hidden_on_focusable.rb` |
| `html-no-empty-headings` | `rules/html/no_empty_headings.rb` |
| `html-no-positive-tab-index` | `rules/html/no_positive_tab_index.rb` |
| `html-no-title-attribute` | `rules/html/no_title_attribute.rb` |

**実装手順:**
- [ ] 上記 14 ファイルの `def self.default_severity` を `"error"` から `"warning"` に変更
- [ ] 各ルールのスペックで severity のアサーションを `"warning"` に更新
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認

---

### Task 26.5: `html-anchor-require-href` ルールの拡張

TypeScript v0.9.0 で `html-anchor-require-href` ルールが大幅に拡張された。

**変更点:**
1. 訪問対象が `visit_html_open_tag_node` → `visit_html_element_node` に変更
2. 新しい違反パターン 3 種が追加:
   - `href="#"` — ページトップスクロールは不適切
   - `href="javascript:void(0)"` / `javascript:void` で始まる値 — `<button>` を使うべき
   - `href` の値が `url_for(nil)` を含む（`link_to nil` 相当）
3. `ERBOpenTagNode` を使った Action View ヘルパー (`link_to` 等) の `href` 属性も検査
4. タイポ修正: `AnchorRechireHrefVisitor` → `AnchorRequireHrefVisitor`（Ruby 版では該当なし）

**実装手順:**
- [ ] `herb-lint/lib/herb/lint/rules/html/anchor_require_href.rb` を TypeScript 実装と照合
- [ ] `visit_html_open_tag_node` → `visit_html_element_node` に変更
- [ ] `href="#"` の検出を追加
- [ ] `href="javascript:void..."` の検出を追加
- [ ] `href` の値が `url_for(nil)` を含む場合の検出を追加
- [ ] `ERBOpenTagNode` からの `href` 属性取得ロジックを追加（`ERBOpenTagNode` が利用可能になった場合）
- [ ] スペックに新しい違反パターンのテストケースを追加
- [ ] `(cd herb-lint && ./bin/rspec)` が通ることを確認
