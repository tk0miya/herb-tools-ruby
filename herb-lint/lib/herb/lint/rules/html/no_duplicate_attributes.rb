# frozen_string_literal: true

# Source: https://github.com/marcoroth/herb/blob/main/javascript/packages/linter/src/rules/html-no-duplicate-attributes.ts
# Documentation: https://herb-tools.dev/linter/rules/html-no-duplicate-attributes

module Herb
  module Lint
    module Rules
      module Html
        # Description:
        #   Disallow having multiple attributes with the same name on a single HTML tag.
        #
        # Good:
        #   <input type="text" name="username" id="user-id" autocomplete="off">
        #
        #   <button type="submit" disabled>Submit</button>
        #
        # Bad:
        #   <input type="text" type="password" name="username" autocomplete="off">
        #
        #   <button type="submit" type="button" disabled>Submit</button>
        #
        class NoDuplicateAttributes < VisitorRule # rubocop:disable Metrics/ClassLength
          def self.rule_name = "html-no-duplicate-attributes" #: String
          def self.description = "Disallow duplicate attributes on the same element" #: String
          def self.default_severity = "error" #: String
          def self.safe_autofixable? = false #: bool
          def self.unsafe_autofixable? = false #: bool

          # Control flow types
          LOOP = :loop #: Symbol
          CONDITIONAL = :conditional #: Symbol

          # @rbs @tag_attributes: Set[String]
          # @rbs @current_branch_attributes: Set[String]
          # @rbs @control_flow_attributes: Set[String]

          # @rbs override
          def on_new_investigation
            @control_flow_stack = [] #: Array[[Symbol, bool]]
            @tag_attributes = Set.new #: Set[String]
            @current_branch_attributes = Set.new #: Set[String]
            @control_flow_attributes = Set.new #: Set[String]
          end

          # @rbs override
          def visit_html_open_tag_node(node)
            @tag_attributes.clear
            @current_branch_attributes.clear
            @control_flow_attributes.clear
            super
          end

          # @rbs override
          def visit_html_attribute_node(node)
            check_attribute(node)
            super
          end

          # Control flow: loops
          # @rbs override
          def visit_erb_block_node(node)
            with_control_flow(LOOP) { super }
          end

          # @rbs override
          def visit_erb_for_node(node)
            with_control_flow(LOOP) { super }
          end

          # @rbs override
          def visit_erb_while_node(node)
            with_control_flow(LOOP) { super }
          end

          # @rbs override
          def visit_erb_until_node(node)
            with_control_flow(LOOP) { super }
          end

          # Control flow: conditionals
          # @rbs override
          def visit_erb_if_node(node)
            with_control_flow(CONDITIONAL) { super }
          end

          # @rbs override
          def visit_erb_unless_node(node)
            with_control_flow(CONDITIONAL) { super }
          end

          # @rbs override
          def visit_erb_case_node(node)
            with_control_flow(CONDITIONAL) { super }
          end

          # @rbs override
          def visit_erb_case_match_node(node)
            with_control_flow(CONDITIONAL) { super }
          end

          # Branches within control flow
          # @rbs override
          def visit_erb_else_node(node)
            with_branch { super }
          end

          # @rbs override
          def visit_erb_elsif_node(node)
            with_branch { super }
          end

          # @rbs override
          def visit_erb_when_node(node)
            with_branch { super }
          end

          private

          attr_reader :control_flow_stack #: Array[[Symbol, bool]]

          # @rbs node: Herb::AST::HTMLAttributeNode
          def check_attribute(node) #: void
            name = attribute_name(node)
            return if name.nil?

            identifier = name.downcase

            effective_type = in_loop? ? LOOP : current_control_flow_type

            case effective_type
            when nil
              handle_html_attribute(identifier, name, node)
            when LOOP
              handle_loop_attribute(identifier, name, node)
            when CONDITIONAL
              handle_conditional_attribute(identifier, name, node)
            end

            @current_branch_attributes.add(identifier)
          end

          # @rbs identifier: String
          # @rbs name: String
          # @rbs node: Herb::AST::HTMLAttributeNode
          def handle_html_attribute(identifier, name, node) #: void
            add_duplicate_attribute_offense(name, node.location) if @tag_attributes.include?(identifier)

            @tag_attributes.add(identifier)
          end

          # @rbs identifier: String
          # @rbs name: String
          # @rbs node: Herb::AST::HTMLAttributeNode
          def handle_loop_attribute(identifier, name, node) #: void
            if @current_branch_attributes.include?(identifier)
              add_same_loop_iteration_offense(name, node.location)
            elsif @tag_attributes.include?(identifier)
              add_duplicate_attribute_offense(name, node.location)
            else
              add_loop_will_duplicate_offense(name, node.location)
            end
          end

          # @rbs identifier: String
          # @rbs name: String
          # @rbs node: Herb::AST::HTMLAttributeNode
          def handle_conditional_attribute(identifier, name, node) #: void
            if @current_branch_attributes.include?(identifier)
              add_same_branch_offense(name, node.location)
            elsif @tag_attributes.include?(identifier)
              add_duplicate_attribute_offense(name, node.location)
              @control_flow_attributes.add(identifier)
            else
              @control_flow_attributes.add(identifier)
            end
          end

          # @rbs name: String
          # @rbs location: Herb::Location
          def add_duplicate_attribute_offense(name, location) #: void
            add_offense(
              message: "Duplicate attribute `#{name}`. " \
                       "Browsers only use the first occurrence and ignore duplicate attributes",
              location:
            )
          end

          # @rbs name: String
          # @rbs location: Herb::Location
          def add_same_loop_iteration_offense(name, location) #: void
            add_offense(
              message: "Duplicate attribute `#{name}` in same loop iteration. " \
                       "Each iteration will produce an element with duplicate attributes",
              location:
            )
          end

          # @rbs name: String
          # @rbs location: Herb::Location
          def add_loop_will_duplicate_offense(name, location) #: void
            add_offense(
              message: "Attribute `#{name}` inside loop will appear multiple times on this element. " \
                       "Use a dynamic attribute name or move the attribute outside the loop",
              location:
            )
          end

          # @rbs name: String
          # @rbs location: Herb::Location
          def add_same_branch_offense(name, location) #: void
            add_offense(
              message: "Duplicate attribute `#{name}` in same branch. " \
                       "This branch will produce an element with duplicate attributes",
              location:
            )
          end

          # Control flow tracking

          # @rbs control_flow_type: Symbol
          def with_control_flow(control_flow_type) #: void
            was_already_in_control_flow = in_control_flow?

            control_flow_stack.push([control_flow_type, was_already_in_control_flow])

            saved_branch_attributes = @current_branch_attributes
            @current_branch_attributes = Set.new

            saved_control_flow_attributes = nil
            unless was_already_in_control_flow
              saved_control_flow_attributes = @control_flow_attributes
              @control_flow_attributes = Set.new
            end

            yield
          ensure
            control_flow_stack.pop

            if control_flow_type == CONDITIONAL && !was_already_in_control_flow
              @control_flow_attributes.each { @tag_attributes.add(_1) }
            end

            @current_branch_attributes = saved_branch_attributes
            @control_flow_attributes = saved_control_flow_attributes if saved_control_flow_attributes
          end

          def with_branch #: void
            return yield unless in_control_flow?

            saved_branch_attributes = @current_branch_attributes
            @current_branch_attributes = Set.new

            yield
          ensure
            @current_branch_attributes = saved_branch_attributes if saved_branch_attributes
          end

          def in_control_flow? #: bool
            !control_flow_stack.empty?
          end

          def in_loop? #: bool
            control_flow_stack.any? { |type, _| type == LOOP }
          end

          def current_control_flow_type #: Symbol?
            return nil if control_flow_stack.empty?

            control_flow_stack.last[0]
          end
        end
      end
    end
  end
end
