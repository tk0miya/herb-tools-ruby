# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-meta-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-meta-names

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when multiple `<meta>` tags share the same `name` or `http-equiv`
        #   attribute within the same `<head>` block, unless they are wrapped in
        #   conditional comments.
        #
        # Good:
        #   <head>
        #     <meta name="description" content="Welcome to our site">
        #     <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #   </head>
        #
        #   <head>
        #     <% if mobile? %>
        #       <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #     <% else %>
        #       <meta name="viewport" content="width=1024">
        #     <% end %>
        #   </head>
        #
        # Bad:
        #   <head>
        #     <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #     <meta name="viewport" content="width=1024">
        #   </head>
        #
        #   <head>
        #     <meta http-equiv="X-UA-Compatible" content="IE=edge">
        #     <meta http-equiv="X-UA-Compatible" content="chrome=1">
        #   </head>
        #
        #   <head>
        #     <meta name="viewport" content="width=1024">
        #
        #     <% if mobile? %>
        #       <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #     <% else %>
        #       <meta http-equiv="refresh" content="30">
        #     <% end %>
        #   </head>
        #
        class NoDuplicateMetaNames < VisitorRule
          def self.rule_name = "html-no-duplicate-meta-names" #: String
          def self.description = "Disallow duplicate meta elements with the same name attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @seen_meta_names: Hash[String, Herb::Location]

          # @rbs override
          def on_new_investigation
            super
            @seen_meta_names = {}
          end

          # @rbs override
          def visit_html_element_node(node)
            check_duplicate_meta_name(node) if meta_element?(node)
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def meta_element?(node) #: bool
            tag_name(node) == "meta"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_meta_name(node) #: void
            name_attr = find_attribute(node, "name")
            name_value = attribute_value(name_attr)
            return if name_value.nil? || name_value.empty?

            normalized_name = name_value.downcase

            if @seen_meta_names.key?(normalized_name)
              first_line = @seen_meta_names[normalized_name].start.line
              add_offense(
                message: "Duplicate meta name '#{name_value}' (first defined at line #{first_line})",
                location: node.location
              )
            else
              @seen_meta_names[normalized_name] = node.location
            end
          end
        end
      end
    end
  end
end
