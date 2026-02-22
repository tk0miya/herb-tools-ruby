# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

  describe "#visit_erb_if_node" do
    subject { printer.capture { printer.visit(node) } }

    let(:parse_result) { Herb.parse(source, track_whitespace: true) }
    let(:printer) do
      Class.new(described_class) do
        attr_accessor :inline_mode, :current_attribute_name
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "when inline_mode is true" do
      before { printer.inline_mode = true }

      context "with HTMLAttributeNode statements (non-token-list context)" do
        let(:source) { '<div <% if disabled %>class="disabled"<% end %>></div>' }
        let(:node) do
          element = parse_result.value.children.first
          open_tag = element.open_tag
          open_tag.child_nodes.find { |c| c.is_a?(Herb::AST::ERBIfNode) }
        end

        it "renders condition tag, space, attribute, space before end, and end tag" do
          expect(subject.join).to eq('<% if disabled %> class="disabled" <% end %>')
        end
      end

      context "with LiteralNode statements in token-list attribute" do
        let(:node) do
          open_tag = parse_result.value.children.first
          attr = open_tag.child_nodes.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
          attr.value.children.find { |c| c.is_a?(Herb::AST::ERBIfNode) }
        end

        context "with class attribute" do
          let(:source) { '<div class="btn<%if active%>active<%end%>">' }

          before { printer.current_attribute_name = "class" }

          it "adds spaces before statement content and before end tag" do
            expect(subject.join).to eq("<% if active %> active <% end %>")
          end
        end

        context "with data-controller attribute" do
          let(:source) { '<div data-controller="btn<%if active%>active<%end%>">' }

          before { printer.current_attribute_name = "data-controller" }

          it "adds spaces before statement content and before end tag" do
            expect(subject.join).to eq("<% if active %> active <% end %>")
          end
        end

        context "with data-action attribute" do
          let(:source) { '<div data-action="btn<%if active%>active<%end%>">' }

          before { printer.current_attribute_name = "data-action" }

          it "adds spaces before statement content and before end tag" do
            expect(subject.join).to eq("<% if active %> active <% end %>")
          end
        end
      end

      context "with LiteralNode statements in non-token-list attribute" do
        let(:node) do
          open_tag = parse_result.value.children.first
          attr = open_tag.child_nodes.find { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
          attr.value.children.find { |c| c.is_a?(Herb::AST::ERBIfNode) }
        end

        context "with id attribute" do
          let(:source) { '<div id="<%if cond%>active<%end%>">' }

          before { printer.current_attribute_name = "id" }

          it "does not add extra spaces" do
            expect(subject.join).to eq("<% if cond %>active<% end %>")
          end
        end

        context "with nil current_attribute_name" do
          let(:source) { '<div id="<%if cond%>active<%end%>">' }

          it "does not add extra spaces" do
            expect(subject.join).to eq("<% if cond %>active<% end %>")
          end
        end
      end
    end

    context "when inline_mode is false" do
      before { printer.inline_mode = false }

      let(:node) { parse_result.value.children.first }

      context "with basic if block" do
        let(:source) { "<% if user.admin? %><%= link_to \"Admin\", admin_path %><% end %>" }

        it "indents statements and places end tag on its own line" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% if user.admin? %>
              <%= link_to "Admin", admin_path %>
            <% end %>
          EXPECTED
        end
      end

      context "with nested ERB if" do
        let(:source) { "<% if outer %><% if inner %><%= text %><% end %><% end %>" }

        it "indents each level of nesting" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% if outer %>
              <% if inner %>
                <%= text %>
              <% end %>
            <% end %>
          EXPECTED
        end
      end
    end
  end

  describe "#visit_erb_content_node" do
    subject { printer.capture { printer.visit(node) } }

    let(:printer) do
      Class.new(described_class) do
        attr_accessor :inline_mode, :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with indentation" do
      let(:node) { Herb.parse("<%=@user.name%>").value.children.first }

      before { printer.indent_level = 1 }

      it "applies current indentation" do
        expect(subject).to eq(["  <%= @user.name %>"])
      end
    end

    context "when in inline mode" do
      let(:node) { Herb.parse("<%=@user.name%>").value.children.first }

      before { printer.inline_mode = true }

      it "does not add indentation" do
        expect(subject).to eq(["<%= @user.name %>"])
      end

      context "with indent level set" do
        before { printer.indent_level = 2 }

        it "ignores indent level" do
          expect(subject).to eq(["<%= @user.name %>"])
        end
      end
    end
  end
end
