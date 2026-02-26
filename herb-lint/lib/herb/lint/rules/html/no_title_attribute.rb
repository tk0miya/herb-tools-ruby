# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-title-attribute.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-title-attribute

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Discourage the use of the `title` attribute on most HTML elements, as it provides poor accessibility
        #   and user experience. The `title` attribute is only accessible via mouse hover and is not reliably
        #   exposed to screen readers or keyboard users.
        #
        # Good:
        #   <!-- Use visible text instead of title -->
        #   <button>Save document</button>
        #   <span class="help-text">Click to save your changes</span>
        #
        #   <!-- Use aria-label for accessible names -->
        #   <button aria-label="Close dialog">×</button>
        #
        #   <!-- Use aria-describedby for additional context -->
        #   <input type="password" aria-describedby="pwd-help" autocomplete="off">
        #   <div id="pwd-help">Password must be at least 8 characters</div>
        #
        #   <!-- Exceptions: title allowed on iframe and links -->
        #   <iframe src="https://example.com" title="Example website content"></iframe>
        #   <link href="default.css" rel="stylesheet" title="Default Style">
        #
        # Bad:
        #   <!-- Don't use title for essential information -->
        #   <button title="Save your changes">Save</button>
        #
        #   <div title="This is important information">Content</div>
        #
        #   <span title="Required field">*</span>
        #
        #   <!-- Don't use title on form elements -->
        #   <input type="text" title="Enter your name" autocomplete="off">
        #
        #   <select title="Choose your country">
        #     <option>US</option>
        #     <option>CA</option>
        #   </select>
        #
        class NoTitleAttribute < VisitorRule
          ALLOWED_ELEMENTS_WITH_TITLE = %w[iframe link].freeze #: Array[String]

          def self.rule_name = "html-no-title-attribute" #: String
          def self.description = "Disallow use of `title` attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_open_tag_node(node)
            check_title_attribute(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLOpenTagNode
          def check_title_attribute(node) #: void
            tag = tag_name(node)
            return if tag.nil? || ALLOWED_ELEMENTS_WITH_TITLE.include?(tag)
            return unless title_attribute?(node)

            add_offense(
              message: "The `title` attribute should never be used as it is inaccessible for several groups of " \
                       "users. Use `aria-label` or `aria-describedby` instead. Exceptions are provided for " \
                       "`<iframe>` and `<link>` elements.",
              location: node.tag_name&.location || node.location
            )
          end

          # @rbs node: Herb::AST::HTMLOpenTagNode
          def title_attribute?(node) #: bool
            node.children.any? do |child|
              child.is_a?(Herb::AST::HTMLAttributeNode) && attribute_name(child)&.downcase == "title"
            end
          end
        end
      end
    end
  end
end
