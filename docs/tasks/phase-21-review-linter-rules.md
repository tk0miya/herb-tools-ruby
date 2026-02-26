# Linter Rules Review Task List

This document contains the task list for reviewing and updating all implemented linter rules.

## Review Process

For each rule, complete the following 8 steps:

1. **Remove the existing Description comment** at the top of the rule class (Description, Good, and Bad comment blocks)

2. **Check the original herb-lint documentation** at https://github.com/marcoroth/herb/tree/main/javascript/packages/linter/docs/rules

3. **Read the Description and Examples** (Good/Bad) from the documentation

4. **Add the Description and Examples as comments** at the top of the rule class:
   - Add "Description:" heading (format: `# Description:` with 1 space)
   - Copy the Description text verbatim (word-for-word, including all paragraphs)
   - **IMPORTANT: Copy ONLY the Description section. DO NOT copy Rationale, Examples, or other sections**
   - Indent each line of Description content with `#   ` (hash + 3 spaces)
   - DO NOT paraphrase, rewrite, or add your own explanations
   - Add blank line after Description
   - Add "Good:" heading with blank line before it (format: `# Good:` with 1 space)
   - Copy all Good examples with `#   ` (hash + 3 spaces) before each line
   - Use existing Ruby codebase indentation within the examples
   - Add blank line after Good section
   - Add "Bad:" heading with blank line before it (format: `# Bad:` with 1 space)
   - Copy all Bad examples with `#   ` (hash + 3 spaces) before each line
   - Add blank line after Bad section
   - Use plain text format, not YARD format

5. **Review and update test cases:**
   - **PRIORITY**: Use Good/Bad examples from the original documentation as the source of truth
   - **REMOVE DUPLICATES**: Delete any existing test cases that duplicate the documentation examples
   - Add comments `# Good examples from documentation` and `# Bad examples from documentation`
   - For each Good example: add test case with `it "does not report an offense"`
   - For each Bad example: add test case with `it "reports an offense"`
   - Keep existing additional test cases ONLY if they test edge cases NOT covered by documentation
   - Add test cases only if documentation examples are missing from tests

6. **Check the original herb-lint rule implementation** (TypeScript/JavaScript)

7. **Compare the Ruby version with the original** and document differences

8. **(Optional) Apply the original version's logic** if significant differences are found

## Rules to Review

### ERB Rules (13 rules)

#### erb/comment-syntax
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-case-node-children
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-empty-tags
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-extra-newline
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-extra-whitespace-inside-tags
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-output-control-flow
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/no-silent-tag-in-attribute-name
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/prefer-image-tag-helper
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/require-trailing-newline
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/require-whitespace-inside-tags
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/right-trim
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/strict-locals-comment-syntax
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### erb/strict-locals-required
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

### HERB Rules (5 rules)

#### herb/disable-comment-malformed
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### herb/disable-comment-missing-rules
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### herb/disable-comment-no-duplicate-rules
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### herb/disable-comment-no-redundant-all
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### herb/disable-comment-valid-rule-name
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

### HTML Rules (31 rules)

#### html/anchor-require-href
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/aria-attribute-must-be-valid
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/aria-label-is-well-formatted
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/aria-level-must-be-valid
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/aria-role-heading-requires-level
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/aria-role-must-be-valid
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/attribute-double-quotes
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/attribute-equals-spacing
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/attribute-values-require-quotes
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/avoid-both-disabled-and-aria-disabled
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/body-only-elements
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/boolean-attributes-no-value
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/head-only-elements
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/iframe-has-title
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/img-require-alt
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/input-require-autocomplete
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/navigation-has-label
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-aria-hidden-on-focusable
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-block-inside-inline
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-duplicate-attributes
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-duplicate-ids
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-duplicate-meta-names
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-empty-attributes
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-empty-headings
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-nested-links
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-positive-tab-index
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-self-closing
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-space-in-tag
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-title-attribute
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/no-underscores-in-attribute-names
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

#### html/tag-name-lowercase
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

### SVG Rules (1 rule)

#### svg/tag-name-capitalization
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

### Parser Rules (1 rule)

#### parser/no-errors
- [x] Step 1: Remove existing comment
- [x] Step 2: Check documentation
- [x] Step 3: Read Description and Examples
- [x] Step 4: Add Description and Examples as comments
- [x] Step 5: Review and update test cases
- [x] Step 6: Check original implementation
- [x] Step 7: Compare and list differences
- [x] Step 8: Apply original logic

## Summary

- **Total Rules**: 51
  - ERB: 13 rules
  - HERB: 5 rules
  - HTML: 31 rules
  - SVG: 1 rule
  - Parser: 1 rule
- **Total Steps**: 408 (51 rules × 8 steps each)

## Progress Tracking

- [ ] ERB rules complete (12/13)
- [ ] HERB rules complete (0/5)
- [ ] HTML rules complete (0/31)
- [ ] SVG rules complete (0/1)
- [x] Parser rules complete (1/1)
