# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-meta-names.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-meta-names

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Warn when multiple `<meta>` tags share the same `name` or `http-equiv` attribute within the same
        #   `<head>` block, unless they are wrapped in conditional comments.
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
          # @rbs @seen_meta_http_equivs: Hash[String, Herb::Location]

          # @rbs override
          def on_new_investigation
            super
            @seen_meta_names = {}
            @seen_meta_http_equivs = {}
          end

          # @rbs override
          def visit_html_element_node(node)
            check_duplicate_meta(node) if meta_element?(node)
            super
          end

          # Process if/elsif/else branches independently so that the same meta name
          # in different branches of a conditional is not reported as a duplicate.
          #
          # @rbs override
          def visit_erb_if_node(node) #: void
            process_conditional_branches(collect_if_branches(node))
          end

          # Process unless/else branches independently so that the same meta name
          # in different branches of a conditional is not reported as a duplicate.
          #
          # @rbs override
          def visit_erb_unless_node(node) #: void
            branches = [node.statements]
            branches << node.else_clause.statements if node.else_clause
            process_conditional_branches(branches)
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          def meta_element?(node) #: bool
            tag_name(node) == "meta"
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_meta(node) #: void
            check_duplicate_meta_name(node)
            check_duplicate_meta_http_equiv(node)
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

          # @rbs node: Herb::AST::HTMLElementNode
          def check_duplicate_meta_http_equiv(node) #: void
            http_equiv_attr = find_attribute(node, "http-equiv")
            http_equiv_value = attribute_value(http_equiv_attr)
            return if http_equiv_value.nil? || http_equiv_value.empty?

            normalized_value = http_equiv_value.downcase

            if @seen_meta_http_equivs.key?(normalized_value)
              first_line = @seen_meta_http_equivs[normalized_value].start.line
              add_offense(
                message: "Duplicate meta http-equiv '#{http_equiv_value}' (first defined at line #{first_line})",
                location: node.location
              )
            else
              @seen_meta_http_equivs[normalized_value] = node.location
            end
          end

          # Collect all branch statement lists from an if/elsif/else chain.
          #
          # @rbs node: Herb::AST::ERBIfNode
          # @rbs return: Array[untyped]
          def collect_if_branches(node) #: Array[untyped]
            branches = []
            current = node
            while current.is_a?(Herb::AST::ERBIfNode)
              branches << current.statements
              current = current.subsequent
            end
            branches << current.statements if current.is_a?(Herb::AST::ERBElseNode)
            branches
          end

          # Process a list of branches independently: each branch starts from the
          # pre-conditional state so that duplicate meta tags across branches are
          # not flagged. After all branches, the union of additions is merged back.
          #
          # @rbs branches: Array[untyped]
          def process_conditional_branches(branches) #: void
            base_meta_names = @seen_meta_names.dup
            base_meta_http_equivs = @seen_meta_http_equivs.dup

            all_branch_meta_names = {}
            all_branch_meta_http_equivs = {}

            branches.each do |branch_statements|
              @seen_meta_names = base_meta_names.dup
              @seen_meta_http_equivs = base_meta_http_equivs.dup

              visit_all(branch_statements)

              all_branch_meta_names.merge!(@seen_meta_names.reject { |k, _| base_meta_names.key?(k) })
              all_branch_meta_http_equivs.merge!(
                @seen_meta_http_equivs.reject { |k, _| base_meta_http_equivs.key?(k) }
              )
            end

            @seen_meta_names = base_meta_names.merge(all_branch_meta_names)
            @seen_meta_http_equivs = base_meta_http_equivs.merge(all_branch_meta_http_equivs)
          end
        end
      end
    end
  end
end
