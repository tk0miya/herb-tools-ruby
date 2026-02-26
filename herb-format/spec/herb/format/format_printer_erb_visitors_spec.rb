# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

  describe ".format" do
    subject { described_class.format(ast, format_context:) }

    let(:ast) { Herb.parse(source, track_whitespace: true) }

    context "with ERBIfNode" do
      context "when in attribute context" do
        context "with HTMLAttributeNode statements (non-token-list context)" do
          let(:source) { '<div <% if disabled %>class="disabled"<% end %>></div>' }

          it "renders condition tag, space, attribute, space before end, and end tag" do
            expect(subject).to eq('<div <% if disabled %> class="disabled" <% end %>></div>')
          end
        end

        context "with LiteralNode statements in token-list attribute" do
          context "with class attribute" do
            let(:source) { '<div class="btn<%if active%>active<%end%>"></div>' }

            it "adds spaces before statement content and before end tag" do
              expect(subject).to eq('<div class="btn<% if active %> active <% end %>"></div>')
            end
          end

          context "with data-controller attribute" do
            let(:source) { '<div data-controller="btn<%if active%>active<%end%>"></div>' }

            it "adds spaces before statement content and before end tag" do
              expect(subject).to eq('<div data-controller="btn<% if active %> active <% end %>"></div>')
            end
          end

          context "with data-action attribute" do
            let(:source) { '<div data-action="btn<%if active%>active<%end%>"></div>' }

            it "adds spaces before statement content and before end tag" do
              expect(subject).to eq('<div data-action="btn<% if active %> active <% end %>"></div>')
            end
          end
        end

        context "with LiteralNode statements in non-token-list attribute" do
          context "with id attribute" do
            let(:source) { '<div id="<%if cond%>active<%end%>"></div>' }

            it "does not add extra spaces" do
              expect(subject).to eq('<div id="<% if cond %>active<% end %>"></div>')
            end
          end
        end
      end

      context "when at document level" do
        context "with basic if block" do
          let(:source) { "<% if user.admin? %><%= link_to \"Admin\", admin_path %><% end %>" }

          it "indents statements and places end tag on its own line" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% if user.admin? %>
                <%= link_to "Admin", admin_path %>
              <% end %>
            EXPECTED
          end
        end

        context "with nested ERB if" do
          let(:source) { "<% if outer %><% if inner %><%= text %><% end %><% end %>" }

          it "indents each level of nesting" do
            expect(subject).to eq(<<~EXPECTED.chomp)
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
        let(:source) { "<% items.each do |item| %><%=@user.name%><% end %>" }

        it "applies current indentation" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              <%= @user.name %>
            <% end %>
          EXPECTED
        end
      end

      context "when in inline context" do
        let(:source) { "<span><%=@user.name%></span>" }

        it "does not add indentation" do
          expect(subject).to eq("<span><%= @user.name %></span>")
        end
      end
    end

    context "with ERBBlockNode" do
      context "when body contains no text content (block mode)" do
        context "with ERB output expression in body" do
          let(:source) { "<% users.each do |user| %><%= user.name %><% end %>" }

          it "indents the body and places the end tag on its own line" do
            expect(subject).to eq(<<~EXPECTED.chomp)
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
            expect(subject).to eq(<<~EXPECTED.chomp)
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
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
              <% end %>
            EXPECTED
          end
        end

        context "with only plain text in body" do
          let(:source) { "<% items.each do |item| %>Hello world<% end %>" }

          it "places end tag on its own line" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>Hello world
              <% end %>
            EXPECTED
          end
        end

        context "with text and a block-level element in body" do
          let(:source) { "<% items.each do |item| %>Hello <div>block</div><% end %>" }

          it "places the block element on its own line" do
            expect(subject).to eq(
              "<% items.each do |item| %>Hello \n  " \
              "<div>block</div>\n" \
              "<% end %>"
            )
          end
        end

        context "with text and a control-flow ERB node in body" do
          let(:source) { "<% items.each do |item| %>Hello <% if cond %>yes<% end %><% end %>" }

          it "places end tag on its own line" do
            expect(subject).to eq(
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

          it "wraps ERB and text as a single indented flow line" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                <%= item %> item
              <% end %>
            EXPECTED
          end
        end

        context "with text and an inline element in body" do
          let(:source) { "<% items.each do |item| %>Hello <strong>item</strong>!<% end %>" }

          it "wraps text and inline element as a single indented flow line" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                Hello <strong>item</strong>!
              <% end %>
            EXPECTED
          end
        end
      end
    end

    context "with ERBUnlessNode" do
      context "with basic unless block" do
        let(:source) { "<% unless user.admin? %><%= text %><% end %>" }

        it "indents statements and places end tag on its own line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% unless user.admin? %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end

      context "with nested unless blocks" do
        let(:source) { "<% unless outer %><% unless inner %><%= text %><% end %><% end %>" }

        it "indents each level of nesting" do
          expect(subject).to eq(<<~EXPECTED.chomp)
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
          expect(subject).to eq(<<~EXPECTED.chomp)
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
      context "with basic for loop" do
        let(:source) { "<% for i in 1..10 %><%= i %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% for i in 1..10 %>
              <%= i %>
            <% end %>
          EXPECTED
        end
      end

      context "with nested for loops" do
        let(:source) { "<% for i in list %><% for j in i.items %><%= j %><% end %><% end %>" }

        it "indents each level of nesting" do
          expect(subject).to eq(<<~EXPECTED.chomp)
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
      context "with basic while loop" do
        let(:source) { "<% while cond %><%= text %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% while cond %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBUntilNode" do
      context "with basic until loop" do
        let(:source) { "<% until cond %><%= text %><% end %>" }

        it "indents the body and places the end tag on its own line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% until cond %>
              <%= text %>
            <% end %>
          EXPECTED
        end
      end
    end

    context "with ERBCaseNode" do
      context "with when clauses" do
        let(:source) { "<% case x %><% when 1 %><%= one %><% when 2 %><%= two %><% end %>" }

        it "renders case tag, when clauses with indented statements, and end tag" do
          expect(subject).to eq(<<~EXPECTED.chomp)
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
          expect(subject).to eq(<<~EXPECTED.chomp)
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
      context "with in clauses" do
        let(:source) { "<% case x %><% in 1 %><%= one %><% in 2 %><%= two %><% end %>" }

        it "renders case tag, in clauses with indented statements, and end tag" do
          expect(subject).to eq(<<~EXPECTED.chomp)
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
          expect(subject).to eq(<<~EXPECTED.chomp)
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
          expect(subject).to eq(<<~EXPECTED.chomp)
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

    context "with ERBCommentNode" do
      context "when at document level" do
        context "with single-line comment without spaces" do
          let(:source) { "<%#comment%>" }

          it "normalizes to <%# content %> format" do
            expect(subject).to eq("<%# comment %>")
          end
        end

        context "with single-line comment with extra spaces" do
          let(:source) { "<%#  comment  %>" }

          it "normalizes spacing to exactly one space" do
            expect(subject).to eq("<%# comment %>")
          end
        end

        context "with single-line comment already normalized" do
          let(:source) { "<%# comment %>" }

          it "preserves normalized format" do
            expect(subject).to eq("<%# comment %>")
          end
        end

        context "with empty comment" do
          let(:source) { "<%#%>" }

          it "outputs empty comment" do
            expect(subject).to eq("<%#%>")
          end
        end

        context "with multi-line comment having single content line" do
          let(:source) { "<%#\n  comment\n%>" }

          it "collapses to single-line format" do
            expect(subject).to eq("<%# comment %>")
          end
        end

        context "with true multi-line comment" do
          let(:source) { "<%#\n  line1\n  line2\n%>" }

          it "formats as block with opening tag, indented content, and closing tag" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <%#
                line1
                line2
              %>
            EXPECTED
          end
        end

        context "with multi-line comment and extra whitespace" do
          let(:source) { "<%#\n    line1\n    line2\n    line3\n%>" }

          it "dedents and reformats as block" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <%#
                line1
                line2
                line3
              %>
            EXPECTED
          end
        end

        context "with multi-line comment with internal blank lines" do
          let(:source) { "<%#\n  line1\n\n  line2\n%>" }

          it "preserves internal blank lines" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <%#
                line1

                line2
              %>
            EXPECTED
          end
        end
      end

      context "with indented context" do
        context "with single-line comment" do
          let(:source) { "<% items.each do |item| %><%#comment%><% end %>" }

          it "adds indentation" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                <%# comment %>
              <% end %>
            EXPECTED
          end
        end

        context "with multi-line comment" do
          let(:source) { "<% items.each do |item| %><%#\n  line1\n  line2\n%><% end %>" }

          it "applies indentation to all parts" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                <%#
                  line1
                  line2
                %>
              <% end %>
            EXPECTED
          end
        end

        context "with multi-line comment with internal blank lines" do
          let(:source) { "<% items.each do |item| %><%#\n  line1\n\n  line2\n%><% end %>" }

          it "preserves internal blank lines with indentation" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% items.each do |item| %>
                <%#
                  line1

                  line2
                %>
              <% end %>
            EXPECTED
          end
        end
      end

      context "when in inline context" do
        context "with single-line comment" do
          let(:source) { "<span><%#comment%></span>" }

          it "normalizes inline" do
            expect(subject).to eq("<span><%# comment %></span>")
          end
        end

        context "with empty comment" do
          let(:source) { "<span><%#%></span>" }

          it "outputs empty comment inline" do
            expect(subject).to eq("<span><%#%></span>")
          end
        end

        context "with multi-line comment having single content line" do
          let(:source) { "<span><%#\n  comment\n%></span>" }

          it "collapses to single-line inline" do
            expect(subject).to eq("<span><%# comment %></span>")
          end
        end

        context "with true multi-line comment" do
          let(:source) { "<span><%#\n  line1\n  line2\n%></span>" }

          it "collapses all lines to single inline format" do
            expect(subject).to eq("<span><%# line1 line2 %></span>")
          end
        end
      end
    end
  end
end
