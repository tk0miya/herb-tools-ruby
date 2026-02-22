# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-title-attribute.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-title-attribute

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Discourage the use of the `title` attribute on most HTML elements, as it provides poor
        #   accessibility and user experience. The `title` attribute is only accessible via mouse
        #   hover and is not reliably exposed to screen readers or keyboard users.
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
          # Elements where the title attribute is allowed for specific purposes.
          ALLOWED_ELEMENTS = %w[iframe link].freeze #: Array[String]

          def self.rule_name = "html-no-title-attribute" #: String
          def self.description = "Disallow use of `title` attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool
          def self.enabled_by_default? = false #: bool

          # @rbs override
          def visit_html_element_node(node)
            unless allowed_element?(node)
              title_attr = find_attribute(node, "title")
              if title_attr
                add_offense(
                  message: "Avoid using the 'title' attribute; it is unreliable for screen readers and touch devices",
                  location: title_attr.location
                )
              end
            end
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def allowed_element?(node) #: bool
            name = tag_name(node)
            return false if name.nil?

            ALLOWED_ELEMENTS.include?(name.downcase)
          end
        end
      end
    end
  end
end
