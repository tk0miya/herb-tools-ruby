# Linter Rules Review Task List

This document contains the task list for reviewing and updating all implemented linter rules.

## Review Process

For each rule, complete the following 8 steps:

1. Remove the existing comment at the top of the rule file
2. Check the original herb-lint documentation at https://github.com/marcoroth/herb/tree/main/javascript/packages/linter/docs/rules
3. Read the Description and Examples (Good/Bad) from the documentation
4. Add the Description and Examples as comments at the top of the rule file (plain text format, not YARD format)
5. Review test cases and update them based on the Description and Examples. Overwrite both success and failure cases. Add cases only if missing.
6. Check the original herb-lint rule implementation
7. Compare the Ruby version with the original version and list the differences
8. Apply the original version's logic to the Ruby version

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
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/no-extra-newline
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/no-extra-whitespace-inside-tags
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/no-output-control-flow
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/no-silent-tag-in-attribute-name
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/prefer-image-tag-helper
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/require-trailing-newline
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/require-whitespace-inside-tags
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/right-trim
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/strict-locals-comment-syntax
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### erb/strict-locals-required
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

### HERB Rules (5 rules)

#### herb/disable-comment-malformed
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### herb/disable-comment-missing-rules
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### herb/disable-comment-no-duplicate-rules
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### herb/disable-comment-no-redundant-all
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### herb/disable-comment-valid-rule-name
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

### HTML Rules (31 rules)

#### html/anchor-require-href
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/aria-attribute-must-be-valid
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/aria-label-is-well-formatted
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/aria-level-must-be-valid
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/aria-role-heading-requires-level
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/aria-role-must-be-valid
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/attribute-double-quotes
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/attribute-equals-spacing
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/attribute-values-require-quotes
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/avoid-both-disabled-and-aria-disabled
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/body-only-elements
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/boolean-attributes-no-value
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/head-only-elements
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/iframe-has-title
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/img-require-alt
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/input-require-autocomplete
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/navigation-has-label
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-aria-hidden-on-focusable
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-block-inside-inline
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-duplicate-attributes
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-duplicate-ids
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-duplicate-meta-names
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-empty-attributes
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-empty-headings
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

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
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-self-closing
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-space-in-tag
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-title-attribute
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/no-underscores-in-attribute-names
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

#### html/tag-name-lowercase
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

### SVG Rules (1 rule)

#### svg/tag-name-capitalization
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

### Parser Rules (1 rule)

#### parser/no-errors
- [ ] Step 1: Remove existing comment
- [ ] Step 2: Check documentation
- [ ] Step 3: Read Description and Examples
- [ ] Step 4: Add Description and Examples as comments
- [ ] Step 5: Review and update test cases
- [ ] Step 6: Check original implementation
- [ ] Step 7: Compare and list differences
- [ ] Step 8: Apply original logic

## Summary

- **Total Rules**: 51
  - ERB: 13 rules
  - HERB: 5 rules
  - HTML: 31 rules
  - SVG: 1 rule
  - Parser: 1 rule
- **Total Steps**: 408 (51 rules × 8 steps each)

## Progress Tracking

- [ ] ERB rules complete (0/13)
- [ ] HERB rules complete (0/5)
- [ ] HTML rules complete (0/31)
- [ ] SVG rules complete (0/1)
- [ ] Parser rules complete (0/1)
