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
        class NoDuplicateMetaNames < VisitorRule # rubocop:disable Metrics/ClassLength
          # Internal struct representing a collected <meta> tag with extracted attributes.
          MetaTag = Struct.new(:node, :name_value, :http_equiv_value, :media_value, keyword_init: true)
          private_constant :MetaTag

          def self.rule_name = "html-no-duplicate-meta-names" #: String
          def self.description = "Disallow duplicate meta elements with the same name attribute" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # @rbs @element_stack: Array[String]
          # @rbs @document_metas: Array[untyped]
          # @rbs @current_branch_metas: Array[untyped]
          # @rbs @control_flow_metas: Array[untyped]
          # @rbs @in_control_flow: bool
          # @rbs @control_flow_type: Symbol?

          # @rbs override
          def on_new_investigation
            super
            @element_stack = []
            @document_metas = []
            @current_branch_metas = []
            @control_flow_metas = []
            @in_control_flow = false
            @control_flow_type = nil
          end

          # Track element nesting to detect when we are inside <head>.
          # Reset meta tracking on <head> entry. Only process <meta> inside <head>.
          #
          # @rbs override
          def visit_html_element_node(node)
            tag = tag_name(node)&.downcase
            return unless tag

            if tag == "head"
              @document_metas = []
              @current_branch_metas = []
              @control_flow_metas = []
            elsif tag == "meta" && inside_head?
              collect_and_check_meta_tag(node)
            end

            @element_stack.push(tag)
            super
            @element_stack.pop
          end

          # Process if/elsif/else as a conditional: same meta name in different
          # branches is not a duplicate.
          #
          # @rbs override
          def visit_erb_if_node(node)
            process_control_flow(collect_if_branches(node), :conditional)
          end

          # Process unless/else as a conditional: same meta name in different
          # branches is not a duplicate.
          #
          # @rbs override
          def visit_erb_unless_node(node)
            branches = [node.statements]
            branches << node.else_clause.statements if node.else_clause
            process_control_flow(branches, :conditional)
          end

          # Process while loop: meta tags are only checked within the same iteration.
          #
          # @rbs override
          def visit_erb_while_node(node)
            process_control_flow([node.statements], :loop)
          end

          # Process until loop: meta tags are only checked within the same iteration.
          #
          # @rbs override
          def visit_erb_until_node(node)
            process_control_flow([node.statements], :loop)
          end

          # Process for loop: meta tags are only checked within the same iteration.
          #
          # @rbs override
          def visit_erb_for_node(node)
            process_control_flow([node.statements], :loop)
          end

          # Process block (e.g. each do...end): meta tags are only checked within
          # the same iteration.
          #
          # @rbs override
          def visit_erb_block_node(node)
            process_control_flow([node.body || []], :loop)
          end

          private

          def inside_head? #: bool
            @element_stack.include?("head")
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def collect_and_check_meta_tag(node) #: void
            meta_tag = extract_meta_tag(node)
            return unless meta_tag.name_value || meta_tag.http_equiv_value

            if @in_control_flow
              handle_control_flow_meta(meta_tag)
            else
              handle_global_meta(meta_tag)
            end

            @current_branch_metas.push(meta_tag)
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def extract_meta_tag(node) #: untyped
            meta_tag = MetaTag.new(node:)

            name_attr = find_attribute(node, "name")
            name_val = attribute_value(name_attr)
            meta_tag.name_value = name_val if name_val && !name_val.empty?

            http_equiv_attr = find_attribute(node, "http-equiv")
            http_equiv_val = attribute_value(http_equiv_attr)
            meta_tag.http_equiv_value = http_equiv_val if http_equiv_val && !http_equiv_val.empty?

            media_attr = find_attribute(node, "media")
            media_val = attribute_value(media_attr)
            meta_tag.media_value = media_val if media_val && !media_val.empty?

            meta_tag
          end

          # @rbs meta_tag: untyped
          def handle_control_flow_meta(meta_tag) #: void
            if @control_flow_type == :loop
              check_against_meta_list(meta_tag, @current_branch_metas, "within the same loop iteration")
            else
              check_against_meta_list(meta_tag, @current_branch_metas, "within the same control flow branch")
              check_against_meta_list(meta_tag, @document_metas, "")
              @control_flow_metas.push(meta_tag)
            end
          end

          # @rbs meta_tag: untyped
          def handle_global_meta(meta_tag) #: void
            check_against_meta_list(meta_tag, @document_metas, "")
            @document_metas.push(meta_tag)
          end

          # @rbs meta_tag: untyped
          # @rbs existing_metas: Array[untyped]
          # @rbs context: String
          def check_against_meta_list(meta_tag, existing_metas, context) #: void
            existing_metas.each do |existing|
              next unless meta_tags_duplicate?(meta_tag, existing)

              attr_desc = if meta_tag.name_value
                            "name=\"#{meta_tag.name_value}\""
                          else
                            "http-equiv=\"#{meta_tag.http_equiv_value}\""
                          end
              attr_type = meta_tag.name_value ? "Meta names" : "`http-equiv` values"
              context_msg = context.empty? ? "" : " #{context}"

              add_offense(
                message: "Duplicate `<meta>` tag with `#{attr_desc}`#{context_msg}. " \
                         "#{attr_type} should be unique within the `<head>` section.",
                location: meta_tag.node.location
              )
              break
            end
          end

          # @rbs meta1: untyped
          # @rbs meta2: untyped
          def meta_tags_duplicate?(meta1, meta2) #: bool
            return false unless media_values_match?(meta1, meta2)

            return meta1.name_value.downcase == meta2.name_value.downcase if meta1.name_value && meta2.name_value

            if meta1.http_equiv_value && meta2.http_equiv_value
              return meta1.http_equiv_value.downcase == meta2.http_equiv_value.downcase
            end

            false
          end

          # @rbs meta1: untyped
          # @rbs meta2: untyped
          def media_values_match?(meta1, meta2) #: bool
            both_present = meta1.media_value && meta2.media_value
            one_present = meta1.media_value || meta2.media_value
            return true unless one_present
            return false unless both_present

            meta1.media_value.downcase == meta2.media_value.downcase
          end

          # @rbs node: Herb::AST::ERBIfNode
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

          # Process control flow with branch isolation mirroring the TypeScript
          # ControlFlowTrackingVisitor logic:
          #
          # - onEnterControlFlow: save state, reset currentBranchMetas,
          #   reset controlFlowMetas only for outermost control flow context.
          # - onEnterBranch: reset currentBranchMetas for each branch.
          # - onExitBranch: no-op (controlFlowMetas accumulates across branches).
          # - onExitControlFlow: for conditionals at the outermost level, promote
          #   all collected controlFlowMetas to documentMetas.
          #
          # Nested control flow shares the same controlFlowMetas accumulator so
          # that inner conditional metas propagate to the outer context.
          #
          # @rbs branch_statements_list: Array[untyped]
          # @rbs flow_type: Symbol
          def process_control_flow(branch_statements_list, flow_type) #: void
            was_already_in_control_flow = @in_control_flow

            # onEnterControlFlow
            saved_current_branch_metas = @current_branch_metas
            saved_control_flow_type = @control_flow_type
            saved_control_flow_metas = @control_flow_metas unless was_already_in_control_flow

            @current_branch_metas = []
            @in_control_flow = true
            @control_flow_type = flow_type
            @control_flow_metas = [] unless was_already_in_control_flow

            # onEnterBranch / visit / onExitBranch (no-op) for each branch
            branch_statements_list.each do |branch_statements|
              @current_branch_metas = []
              visit_all(branch_statements)
            end

            # onExitControlFlow
            @document_metas.concat(@control_flow_metas) if flow_type == :conditional && !was_already_in_control_flow

            @current_branch_metas = saved_current_branch_metas
            @in_control_flow = was_already_in_control_flow
            @control_flow_type = saved_control_flow_type
            @control_flow_metas = saved_control_flow_metas unless was_already_in_control_flow
          end
        end
      end
    end
  end
end
