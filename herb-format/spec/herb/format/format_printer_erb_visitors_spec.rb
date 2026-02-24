# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

  describe ".visit" do
    subject { printer.capture { printer.visit(node) } }

    let(:parse_result) { Herb.parse(source, track_whitespace: true) }
    let(:printer) do
      Class.new(described_class) do
        attr_accessor :current_attribute_name, :indent_level, :inline_mode
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with ERBIfNode" do
      context "when inline_mode is true" do
        before { printer.inline_mode = true }

        context "with HTMLAttributeNode statements (non-token-list context)" do
          let(:source) { '<div <% if disabled %>class="disabled"<% end %>></div>' }
          let(:node) do
            element = parse_result.value.children.first
            open_tag = element.open_tag
            open_tag.child_nodes.find { _1.is_a?(Herb::AST::ERBIfNode) }
          end

          it "renders condition tag, space, attribute, space before end, and end tag" do
            expect(subject.join).to eq('<% if disabled %> class="disabled" <% end %>')
          end
        end

        context "with LiteralNode statements in token-list attribute" do
          let(:node) do
            open_tag = parse_result.value.children.first
            attr = open_tag.child_nodes.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
            attr.value.children.find { _1.is_a?(Herb::AST::ERBIfNode) }
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
            attr = open_tag.child_nodes.find { _1.is_a?(Herb::AST::HTMLAttributeNode) }
            attr.value.children.find { _1.is_a?(Herb::AST::ERBIfNode) }
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

    context "with ERBContentNode" do
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

    context "with ERBBlockNode" do
      let(:node) { parse_result.value.children.first }

      context "when body contains no text content (block mode)" do
        context "with ERB output expression in body" do
          let(:source) { "<% users.each do |user| %><%= user.name %><% end %>" }

          it "indents the body and places the end tag on its own line" do
            expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
              <% users.each do |user| %>
                <%= user.name %>
              <% end %>
            EXPECTED
          end
        end

        context "with nested each blocks" do
          let(:source) do
            "<% users.each do |user| %><% user.posts.each do |post| %><%= post.title %><% end %><% end %>"
          end

          it "indents each level of nesting" do
            expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
              <% users.each do |user| %>
                <% user.posts.each do |post| %>
                  <%= post.title %>
                <% end %>
              <% end %>
            EXPECTED
          end
        end

        context "with only whitespace between tags" do
          let(:source) { "<% items.each do |item| %>   <% end %>" }

          it "skips whitespace and produces no body output" do
            expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
              <% end %>
            EXPECTED
          end
        end

        context "with only plain text in body" do
          let(:source) { "<% items.each do |item| %>Hello world<% end %>" }

          it "places end tag on its own line" do
            expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>Hello world
              <% end %>
            EXPECTED
          end
        end

        context "with text and a block-level element in body" do
          let(:source) { "<% items.each do |item| %>Hello <div>block</div><% end %>" }

          it "places the block element on its own line" do
            expect(subject.join("\n")).to eq(
              "<% items.each do |item| %>Hello \n  " \
              "<div>block</div>\n" \
              "<% end %>"
            )
          end
        end

        context "with text and a control-flow ERB node in body" do
          let(:source) { "<% items.each do |item| %>Hello <% if cond %>yes<% end %><% end %>" }

          it "places end tag on its own line" do
            expect(subject.join("\n")).to eq(
              "<% items.each do |item| %>Hello \n  " \
              "<% if cond %>yes\n  " \
              "<% end %>\n" \
              "<% end %>"
            )
          end
        end
      end

      context "when body contains text mixed with ERB (text flow mode)" do
        context "with ERB output followed by text in body" do
          let(:source) { "<% items.each do |item| %><%= item %> item<% end %>" }

          it "visits ERB and text children in sequence" do
            expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                <%= item %> item
              <% end %>
            EXPECTED
          end
        end

        context "with text and an inline element in body" do
          let(:source) { "<% items.each do |item| %>Hello <strong>item</strong>!<% end %>" }

          it "visits text and inline element children in sequence" do
            expect(subject.join("\n")).to eq(
              "<% items.each do |item| %>Hello \n  " \
              "<strong>item</strong>!\n" \
              "<% end %>"
            )
          end
        end
      end
    end

    context "with ERBUnlessNode" do
      let(:node) { parse_result.value.children.first }

      context "with basic unless block" do
        let(:source) { "<% unless user.admin? %><%= text %><% end %>" }

        it "indents statements and places end tag on its own line" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% unless user.admin? %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end

      context "with nested unless blocks" do
        let(:source) { "<% unless outer %><% unless inner %><%= text %><% end %><% end %>" }

        it "indents each level of nesting" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% unless outer %>
              <% unless inner %>
                <%= text %>
              <% end %>
            <% end %>
          EXPECTED
        end
      end

      context "with else clause" do
        let(:source) { "<% unless cond %><%= a %><% else %><%= b %><% end %>" }

        it "renders unless, else, and end with correct indentation" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% unless cond %>
              <%= a %>
            <% else %>
              <%= b %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBForNode" do
      let(:node) { parse_result.value.children.first }

      context "with basic for loop" do
        let(:source) { "<% for i in 1..10 %><%= i %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% for i in 1..10 %>
              <%= i %>
            <% end %>
          EXPECTED
        end
      end

      context "with nested for loops" do
        let(:source) { "<% for i in list %><% for j in i.items %><%= j %><% end %><% end %>" }

        it "indents each level of nesting" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% for i in list %>
              <% for j in i.items %>
                <%= j %>
              <% end %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBWhileNode" do
      let(:node) { parse_result.value.children.first }

      context "with basic while loop" do
        let(:source) { "<% while cond %><%= text %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% while cond %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBUntilNode" do
      let(:node) { parse_result.value.children.first }

      context "with basic until loop" do
        let(:source) { "<% until cond %><%= text %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% until cond %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBCaseNode" do
      let(:node) { parse_result.value.children.first }

      context "with when clauses" do
        let(:source) { "<% case x %><% when 1 %><%= one %><% when 2 %><%= two %><% end %>" }

        it "renders case tag, when clauses with indented statements, and end tag" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% case x %>
            <% when 1 %>
              <%= one %>
            <% when 2 %>
              <%= two %>
            <% end %>
          EXPECTED
        end
      end

      context "with else clause" do
        let(:source) { "<% case x %><% when 1 %><%= one %><% else %><%= other %><% end %>" }

        it "renders case tag, when clause, else clause, and end tag" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% case x %>
            <% when 1 %>
              <%= one %>
            <% else %>
              <%= other %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBCaseMatchNode" do
      let(:node) { parse_result.value.children.first }

      context "with in clauses" do
        let(:source) { "<% case x %><% in 1 %><%= one %><% in 2 %><%= two %><% end %>" }

        it "renders case tag, in clauses with indented statements, and end tag" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% case x %>
            <% in 1 %>
              <%= one %>
            <% in 2 %>
              <%= two %>
            <% end %>
          EXPECTED
        end
      end

      context "with else clause" do
        let(:source) { "<% case x %><% in 1 %><%= one %><% else %><%= other %><% end %>" }

        it "renders case tag, in clause, else clause, and end tag" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% case x %>
            <% in 1 %>
              <%= one %>
            <% else %>
              <%= other %>
            <% end %>
          EXPECTED
        end
      end

      context "with pattern matching in clauses" do
        let(:source) { "<% case x %><% in [Integer => n] %><%= n %><% in String %><%= x %><% end %>" }

        it "renders case tag, in clauses with indented statements, and end tag" do
          expect(subject.join("\n")).to eq(<<~EXPECTED.chomp)
            <% case x %>
            <% in [Integer => n] %>
              <%= n %>
            <% in String %>
              <%= x %>
            <% end %>
          EXPECTED
        end
      end
    end
  end
end
