# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-meta-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-meta-names

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when multiple `<meta>` tags share the same `name` or `http-equiv` attribute within
        #   the same `<head>` block, unless they are wrapped in conditional comments.
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
        class NoDuplicateMetaNames < VisitorRule # rubocop:disable Metrics/ClassLength
          def self.rule_name = "html-no-duplicate-meta-names" #: String
          def self.description = "Disallow duplicate meta elements with the same name or http-equiv attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @document_metas: Hash[String, Herb::Location]
          # @rbs @current_branch_metas: Hash[String, Herb::Location]
          # @rbs @control_flow_metas: Hash[String, Herb::Location]
          # @rbs @control_flow_depth: Integer

          # @rbs override
          def on_new_investigation
            super
            @document_metas = {}
            @current_branch_metas = {}
            @control_flow_metas = {}
            @control_flow_depth = 0
          end

          # @rbs override
          def visit_html_element_node(node)
            check_duplicate_meta(node) if meta_element?(node)
            super
          end

          # @rbs override
          def visit_erb_if_node(node)
            with_conditional { super }
          end

          # @rbs override
          def visit_erb_unless_node(node)
            with_conditional { super }
          end

          # @rbs override
          def visit_erb_else_node(node)
            with_branch { super }
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def meta_element?(node) #: bool
            tag_name(node) == "meta"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_meta(node) #: void
            name_value = attribute_value(find_attribute(node, "name"))
            if name_value && !name_value.empty?
              check_meta_key(node, "name", name_value)
              return
            end

            http_equiv_value = attribute_value(find_attribute(node, "http-equiv"))
            return unless http_equiv_value && !http_equiv_value.empty?

            check_meta_key(node, "http-equiv", http_equiv_value)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs attr_type: String
          # @rbs value: String
          def check_meta_key(node, attr_type, value) #: void
            key = "#{attr_type}:#{value.downcase}"

            if in_control_flow?
              check_meta_key_in_branch(node, attr_type, value, key)
            elsif @document_metas.key?(key)
              add_offense(message: build_message(attr_type, value), location: node.location)
            else
              @document_metas[key] = node.location
            end
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs attr_type: String
          # @rbs value: String
          # @rbs key: String
          def check_meta_key_in_branch(node, attr_type, value, key) #: void
            if @current_branch_metas.key?(key)
              add_offense(
                message: build_message(attr_type, value, "within the same control flow branch"),
                location: node.location
              )
            elsif @document_metas.key?(key)
              add_offense(message: build_message(attr_type, value), location: node.location)
              @control_flow_metas[key] = node.location
            else
              @control_flow_metas[key] = node.location
            end
            @current_branch_metas[key] = node.location
          end

          # @rbs attr_type: String
          # @rbs value: String
          # @rbs context: String?
          def build_message(attr_type, value, context = nil) #: String
            context_part = context ? " #{context}" : ""

            if attr_type == "name"
              "Duplicate `<meta>` tag with `name=\"#{value}\"`#{context_part}. " \
                "Meta names should be unique within the `<head>` section."
            else
              "Duplicate `<meta>` tag with `http-equiv=\"#{value}\"`#{context_part}. " \
                "`http-equiv` values should be unique within the `<head>` section."
            end
          end

          def with_conditional #: void
            was_already_in_control_flow = in_control_flow?
            @control_flow_depth += 1

            saved_branch_metas = @current_branch_metas
            @current_branch_metas = {}

            saved_control_flow_metas = nil
            unless was_already_in_control_flow
              saved_control_flow_metas = @control_flow_metas
              @control_flow_metas = {}
            end

            yield
          ensure
            @control_flow_depth -= 1

            unless was_already_in_control_flow
              @document_metas.merge!(@control_flow_metas)
              @control_flow_metas = saved_control_flow_metas || {}
            end

            @current_branch_metas = saved_branch_metas
          end

          def with_branch #: void
            return yield unless in_control_flow?

            saved_branch_metas = @current_branch_metas
            @current_branch_metas = {}

            yield
          ensure
            @current_branch_metas = saved_branch_metas if saved_branch_metas
          end

          def in_control_flow? #: bool
            @control_flow_depth.positive?
          end
        end
      end
    end
  end
end
