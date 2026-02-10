# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-aria-role-must-be-valid.ts
# Documentation: https://herb-tools.dev/linter/rules/html-aria-role-must-be-valid

module Herb
  module Lint
    module Rules
      module Html
        # Rule that validates WAI-ARIA role attribute values.
        #
        # The role attribute must contain a valid WAI-ARIA role.
        # Empty or invalid role values are disallowed.
        #
        # Good:
        #   <div role="button">
        #   <div role="navigation">
        #
        # Bad:
        #   <div role="invalid-role">
        #   <div role="">
        # rubocop:disable Metrics/ClassLength
        class AriaRoleMustBeValid < VisitorRule
          # Valid WAI-ARIA roles from the WAI-ARIA 1.2 specification.
          # Abstract roles (command, composite, input, landmark, range, roletype,
          # section, sectionhead, select, structure, widget, window) are excluded
          # as they must not be used by authors.
          VALID_ROLES = %w[
            alert
            alertdialog
            application
            article
            banner
            blockquote
            button
            caption
            cell
            checkbox
            code
            columnheader
            combobox
            complementary
            contentinfo
            definition
            deletion
            dialog
            directory
            document
            emphasis
            feed
            figure
            form
            generic
            grid
            gridcell
            group
            heading
            img
            insertion
            link
            list
            listbox
            listitem
            log
            main
            marquee
            math
            menu
            menubar
            menuitem
            menuitemcheckbox
            menuitemradio
            meter
            navigation
            none
            note
            option
            paragraph
            presentation
            progressbar
            radio
            radiogroup
            region
            row
            rowgroup
            rowheader
            scrollbar
            search
            searchbox
            separator
            slider
            spinbutton
            status
            strong
            subscript
            superscript
            switch
            tab
            table
            tablist
            tabpanel
            term
            textbox
            timer
            toolbar
            tooltip
            tree
            treegrid
            treeitem
          ].to_set.freeze #: Set[String]

          def self.rule_name #: String
            "html-aria-role-must-be-valid"
          end

          def self.description #: String
            "The role attribute must contain a valid WAI-ARIA role"
          end

          def self.default_severity #: String
            "error"
          end

          def self.safe_autofixable? #: bool
            false
          end

          def self.unsafe_autofixable? #: bool
            false
          end

          # @rbs override
          def visit_html_element_node(node)
            role_attr = find_attribute(node, "role")

            if role_attr
              value = attribute_value(role_attr)

              if value.nil? || value.strip.empty?
                add_offense(
                  message: "The role attribute must not be empty",
                  location: role_attr.location
                )
              else
                validate_roles(value, role_attr)
              end
            end

            super
          end

          private

          # @rbs value: String
          # @rbs role_attr: Herb::AST::HTMLAttributeNode
          def validate_roles(value, role_attr) #: void
            value.split.each do |role|
              next if VALID_ROLES.include?(role.downcase)

              add_offense(
                message: "'#{role}' is not a valid WAI-ARIA role",
                location: role_attr.location
              )
            end
          end
        end
        # rubocop:enable Metrics/ClassLength
      end
    end
  end
end
