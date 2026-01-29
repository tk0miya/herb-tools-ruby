# frozen_string_literal: true

module Herb
  module Lint
    module Rules
      module A11y
        # Rule that disallows redundant ARIA roles matching implicit semantics.
        #
        # Many HTML elements have implicit ARIA roles. Adding an explicit role
        # attribute that matches the element's implicit role is redundant and
        # should be removed to keep markup clean.
        #
        # Good:
        #   <button>Click</button>
        #   <a href="#">Link</a>
        #   <nav>...</nav>
        #
        # Bad:
        #   <button role="button">Click</button>
        #   <a href="#" role="link">Link</a>
        #   <nav role="navigation">...</nav>
        class NoRedundantRole < VisitorRule
          # Mapping of HTML elements to their implicit ARIA roles.
          # @see https://www.w3.org/TR/html-aria/#docconformance
          IMPLICIT_ROLES = {
            "article" => "article",
            "aside" => "complementary",
            "body" => "document",
            "button" => "button",
            "datalist" => "listbox",
            "details" => "group",
            "dialog" => "dialog",
            "fieldset" => "group",
            "figure" => "figure",
            "footer" => "contentinfo",
            "form" => "form",
            "h1" => "heading",
            "h2" => "heading",
            "h3" => "heading",
            "h4" => "heading",
            "h5" => "heading",
            "h6" => "heading",
            "header" => "banner",
            "hr" => "separator",
            "img" => "img",
            "li" => "listitem",
            "main" => "main",
            "menu" => "list",
            "meter" => "meter",
            "nav" => "navigation",
            "ol" => "list",
            "optgroup" => "group",
            "option" => "option",
            "output" => "status",
            "progress" => "progressbar",
            "select" => "listbox",
            "summary" => "button",
            "table" => "table",
            "tbody" => "rowgroup",
            "textarea" => "textbox",
            "tfoot" => "rowgroup",
            "thead" => "rowgroup",
            "ul" => "list"
          }.freeze #: Hash[String, String]

          # Elements where the implicit role depends on having an href attribute.
          HREF_DEPENDENT_ELEMENTS = %w[a area].freeze #: Array[String]

          def self.rule_name #: String
            "a11y/no-redundant-role"
          end

          def self.description #: String
            "Disallow redundant ARIA roles matching implicit semantics"
          end

          def self.default_severity #: String
            "warning"
          end

          # @rbs override
          def visit_html_element_node(node)
            tag_name = node.tag_name&.value&.downcase
            check_redundant_role(node, tag_name) if tag_name
            super
          end

          private

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs tag_name: String
          def check_redundant_role(node, tag_name) #: void
            role_value = find_role_value(node)
            return unless role_value

            implicit_role = implicit_role_for(node, tag_name)
            return unless implicit_role
            return unless role_value.downcase == implicit_role

            add_offense(
              message: "The element '#{tag_name}' has an implicit role of '#{implicit_role}'. " \
                       "Setting role=\"#{role_value}\" is redundant",
              location: node.location
            )
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs tag_name: String
          def implicit_role_for(node, tag_name) #: String?
            if HREF_DEPENDENT_ELEMENTS.include?(tag_name)
              return "link" if attribute?(node, "href")

              return nil
            end

            IMPLICIT_ROLES[tag_name]
          end

          # @rbs node: Herb::AST::HTMLElementNode
          def find_role_value(node) #: String?
            role_attr = find_attribute(node, "role")
            return nil unless role_attr

            value = role_attr.value
            return nil unless value

            value.children.first&.content
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs attr_name: String
          def find_attribute(node, attr_name) #: Herb::AST::HTMLAttributeNode?
            return nil unless node.open_tag

            node.open_tag.children.find do |child|
              next false unless child.is_a?(Herb::AST::HTMLAttributeNode)

              child.name.children.first&.content&.downcase == attr_name
            end
          end

          # @rbs node: Herb::AST::HTMLElementNode
          # @rbs attr_name: String
          def attribute?(node, attr_name) #: bool
            !find_attribute(node, attr_name).nil?
          end
        end
      end
    end
  end
end
