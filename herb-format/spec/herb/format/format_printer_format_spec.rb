# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { build(:context, source:, indent_width:, max_line_length:) }

  describe ".format" do
    subject { described_class.format(ast, format_context:) }

    let(:ast) { Herb.parse(source, track_whitespace: true) }

    context "with basic nodes" do
      context "with document node" do
        let(:source) { "Hello World" }

        it "visits all children" do
          expect(subject).to eq("Hello World")
        end
      end

      context "with literal nodes" do
        let(:source) { "Plain text" }

        it "preserves literal content" do
          expect(subject).to eq("Plain text")
        end
      end
    end

    context "with HTML elements" do
      context "with void elements" do
        let(:source) { "<br>" }

        it "outputs void element without closing tag" do
          expect(subject).to eq("<br>")
        end
      end

      context "with preserved elements" do
        context "with multi-line pre element" do
          let(:source) { "<pre>\n  def hello\n    puts 'world'\n  end\n</pre>" }

          it "preserves all newlines and indentation" do
            expect(subject).to include("\n  def hello\n    puts 'world'\n  end\n")
          end
        end

        context "with textarea element" do
          let(:source) { "<textarea>\n  User input\n    with indents\n</textarea>" }

          it "preserves content as-is" do
            expect(subject).to include("\n  User input\n    with indents\n")
          end
        end

        context "with script element" do
          let(:source) { "<script>\n  console.log('test');\n</script>" }

          it "preserves script content with original formatting" do
            expect(subject).to include("\n  console.log('test');\n")
          end
        end

        context "with style element" do
          let(:source) { "<style>\n  .foo { color: red; }\n</style>" }

          it "preserves style content with original formatting" do
            expect(subject).to include("\n  .foo { color: red; }\n")
          end
        end
      end

      context "with block elements" do
        context "when element content is inline" do
          let(:source) { "<p>Hello</p>" }

          it "appends closing tag on the same line as content" do
            expect(subject).to eq("<p>Hello</p>")
          end
        end

        context "when element content is block" do
          let(:source) { "<div><p>nested</p></div>" }

          it "indents block child and puts close tag on its own line" do
            expect(subject).to eq("<div>\n  <p>nested</p>\n</div>")
          end
        end

        context "with deeply nested block elements" do
          let(:source) { "<section><div><p>text</p></div></section>" }

          it "indents each level correctly" do
            expect(subject).to eq("<section>\n  <div>\n    <p>text</p>\n  </div>\n</section>")
          end
        end

        context "with deeply nested inline elements" do
          let(:source) { "<div><span>inline</span></div>" }

          it "keeps inline child on the same line as parent" do
            expect(subject).to eq("<div><span>inline</span></div>")
          end
        end
      end
    end

    context "with HTML attributes" do
      context "with basic attributes" do
        let(:source) { '<div class="foo" id="bar">content</div>' }

        it "outputs opening tag with attributes, content, and closing tag" do
          expect(subject).to eq('<div class="foo" id="bar">content</div>')
        end
      end

      context "with no attributes" do
        let(:source) { "<div>content</div>" }

        it "renders tag without attribute string" do
          expect(subject).to eq("<div>content</div>")
        end
      end

      context "with boolean attributes" do
        let(:source) { "<input disabled>" }

        it "renders boolean attribute without value" do
          expect(subject).to eq("<input disabled>")
        end
      end

      context "with quote normalization" do
        context "with single-quoted attributes on empty element" do
          let(:source) { "<div class='foo'></div>" }

          it "normalizes single quotes to double quotes" do
            expect(subject).to eq('<div class="foo"></div>')
          end
        end

        context "with multiple single-quoted attributes" do
          let(:source) { "<div id='main' class='container'></div>" }

          it "normalizes single quotes to double quotes" do
            expect(subject).to eq('<div id="main" class="container"></div>')
          end
        end

        context "with single-quoted attribute whose value contains a double quote" do
          let(:source) { %(<div title='say "hello"'></div>) }

          it "preserves single quotes to avoid breaking the attribute value" do
            expect(subject).to eq(%(<div title='say "hello"'></div>))
          end
        end

        context "with unquoted attribute" do
          let(:source) { "<div class=foo></div>" }

          it "adds double quotes" do
            expect(subject).to eq('<div class="foo"></div>')
          end
        end
      end

      context "with ERB in attribute values" do
        let(:source) { '<div class="<%= foo %>">content</div>' }

        it "renders ERB expression inside attribute value" do
          expect(subject).to eq('<div class="<%= foo %>">content</div>')
        end
      end

      context "with class attribute" do
        context "with short class value" do
          let(:source) { '<div class="foo bar">content</div>' }

          it "keeps class attribute on same line" do
            expect(subject).to eq('<div class="foo bar">content</div>')
          end
        end

        context "with extra whitespace in class value" do
          let(:source) { '<div class="  foo   bar  ">content</div>' }

          it "normalizes whitespace in class attribute" do
            expect(subject).to eq('<div class="foo bar">content</div>')
          end
        end

        context "with ERB in class attribute and long value" do
          let(:max_line_length) { 30 }
          let(:source) { '<div class="flex items-center justify-between <%= active_class %>">content</div>' }

          it "normalizes whitespace but does not wrap when ERB is present" do
            expect(subject).to eq(
              '<div class="flex items-center justify-between <%= active_class %>">content</div>'
            )
          end
        end

        context "with long class value exceeding max_line_length" do
          let(:max_line_length) { 60 }
          let(:source) do
            '<div class="flex items-center justify-between px-4 py-2 bg-white shadow-md rounded-lg">content</div>'
          end

          it "wraps long class attribute across multiple lines" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <div class="
                flex items-center justify-between px-4 py-2 bg-white
                shadow-md rounded-lg
              ">content</div>
            EXPECTED
          end
        end

        # Normalized: "flex items-center ... rounded-lg border-2" (82 chars > 80)
        # → newline-wrapping path is taken
        context "when class content has actual newlines and normalized length exceeds 80 chars" do
          let(:source) do
            '<div class="flex items-center' \
              "\njustify-between px-4 py-2 bg-white shadow-md rounded-lg border-2\">content</div>"
          end

          it "wraps using original line breaks" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <div class="
                flex items-center
                justify-between px-4 py-2 bg-white shadow-md rounded-lg border-2
              ">content</div>
            EXPECTED
          end
        end

        # Normalized: "foo bar baz" (11 chars ≤ 80) → newline-wrapping threshold not met
        context "when class content has newlines but normalized length is within 80 chars" do
          let(:source) { "<div class=\"foo\nbar\nbaz\">content</div>" }

          it "normalizes without wrapping" do
            expect(subject).to eq('<div class="foo bar baz">content</div>')
          end
        end

        # normalized_content: "foo bar baz qux quux corge grault" (33 chars ≤ 60)
        # → length-wrapping threshold not met even though line is long
        context "when line exceeds max_line_length but normalized content is within 60 chars" do
          let(:max_line_length) { 40 }
          let(:source) do
            <<~ERB
              <section>
                <article>
                  <div class="foo bar baz qux quux corge grault">content</div>
                </article>
              </section>
            ERB
          end

          it "does not wrap" do
            expect(subject).to include(
              '    <div class="foo bar baz qux quux corge grault">content</div>'
            )
          end
        end

        # normalized_content: 62 chars (> 60), indent_level: 0
        # → all tokens fit in one line (62 < 64), no wrapping
        context "when normalized content exceeds 60 chars and element is at the top level" do
          let(:max_line_length) { 64 }
          let(:source) do
            '<div class="flex items-center justify-between px-4 py-2 bg-white shadow-md">content</div>'
          end

          it "does not wrap" do
            expect(subject).to eq(
              '<div class="flex items-center justify-between px-4 py-2 bg-white shadow-md">content</div>'
            )
          end
        end

        # normalized_content: 62 chars (> 60), indent_level: 2 (indent_width=2 → 4 spaces)
        # → indent offset pushes "shadow-md" over max_line_length → wraps
        context "when normalized content exceeds 60 chars and element is indented" do
          let(:max_line_length) { 64 }
          let(:source) do
            <<~ERB
              <section>
                <article>
                  <div class="flex items-center justify-between px-4 py-2 bg-white shadow-md">content</div>
                </article>
              </section>
            ERB
          end

          it "wraps" do
            expect(subject).to include(
              "    <div class=\"\n  flex items-center justify-between px-4 py-2 bg-white\n  " \
              "shadow-md\n\">content</div>"
            )
          end
        end

        context "when normalized content exceeds 60 chars but has no spaces (single unsplittable token)" do
          let(:max_line_length) { 60 }
          let(:source) { "<div class=\"#{'a' * 65}\">content</div>" }

          it "does not wrap" do
            expect(subject).to eq("<div class=\"#{'a' * 65}\">content</div>")
          end
        end
      end

      context "when open tag has ERB control flow spanning multiple lines" do
        # multi-line ERB if in open tag makes open_tag_inline=false → render_multiline_attributes
        let(:source) { "<div\n<% if condition %>\nclass=\"active\"\n<% end %>\n>content</div>" }

        it "renders conditional attribute with correct syntax and indentation" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% if condition %>
              class="active"
              <% end %>
            >content
            </div>
          ERB
        end
      end

      context "when open tag has ERB if with disabled attribute" do
        let(:source) { "<div\n<% if disabled %>\nclass=\"disabled\"\n<% end %>\n></div>" }

        it "renders class attribute with quotes and correct indentation" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% if disabled %>
              class="disabled"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB if-else with conditional attributes" do
        let(:source) { "<div\n<% if active %>\nclass=\"active\"\n<% else %>\nclass=\"inactive\"\n<% end %>\n></div>" }

        it "renders both branches with correct attribute syntax" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% if active %>
              class="active"
              <% else %>
              class="inactive"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB unless with conditional attribute" do
        let(:source) { "<div\n<% unless enabled %>\nclass=\"disabled\"\n<% end %>\n></div>" }

        it "renders unless conditional attribute with correct syntax and indentation" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% unless enabled %>
              class="disabled"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB unless-else with conditional attributes" do
        let(:source) do
          "<div\n<% unless enabled %>\nclass=\"disabled\"\n<% else %>\nclass=\"enabled\"\n<% end %>\n></div>"
        end

        it "renders unless-else branches with correct attribute syntax" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% unless enabled %>
              class="disabled"
              <% else %>
              class="enabled"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB for loop with conditional attribute" do
        let(:source) { "<div\n<% for cls in classes %>\nclass=\"<%= cls %>\"\n<% end %>\n></div>" }

        it "preserves the for block and attribute (does not silently drop content)" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% for cls in classes %>
              class="<%= cls %>"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB while loop with conditional attribute" do
        let(:source) { "<div\n<% while condition %>\nclass=\"active\"\n<% end %>\n></div>" }

        it "preserves the while block and attribute" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% while condition %>
              class="active"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB case/when with conditional attributes" do
        let(:source) do
          parts = ["<div", "<% case role %>", "<% when :admin %>", "class=\"admin\"",
                   "<% when :user %>", "class=\"user\"", "<% end %>", "></div>"]
          parts.join("\n")
        end

        it "renders each when branch with its attribute" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% case role %>
              <% when :admin %>
              class="admin"
              <% when :user %>
              class="user"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB case/when/else with conditional attributes" do
        let(:source) do
          "<div\n<% case role %>\n<% when :admin %>\nclass=\"admin\"\n<% else %>\nclass=\"guest\"\n<% end %>\n></div>"
        end

        it "renders when branch and else branch with their attributes" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% case role %>
              <% when :admin %>
              class="admin"
              <% else %>
              class="guest"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB case/in with conditional attributes" do
        let(:source) do
          parts = ["<div", "<% case val %>", "<% in :foo %>", "class=\"foo\"",
                   "<% in :bar %>", "class=\"bar\"", "<% end %>", "></div>"]
          parts.join("\n")
        end

        it "renders each in branch with its attribute" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% case val %>
              <% in :foo %>
              class="foo"
              <% in :bar %>
              class="bar"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag has ERB case/in/else with conditional attributes" do
        let(:source) do
          "<div\n<% case val %>\n<% in :foo %>\nclass=\"foo\"\n<% else %>\nclass=\"default\"\n<% end %>\n></div>"
        end

        it "renders in branch and else branch with their attributes" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              <% case val %>
              <% in :foo %>
              class="foo"
              <% else %>
              class="default"
              <% end %>
            >
            </div>
          ERB
        end
      end

      context "when open tag attributes exceed max_line_length" do
        let(:max_line_length) { 30 }
        let(:source) { '<button type="submit" class="btn" disabled></button>' }

        it "renders each attribute on its own indented line" do
          expect(subject).to eq(<<~ERB.chomp)
            <button
              type="submit"
              class="btn"
              disabled
            >
            </button>
          ERB
        end
      end

      context "when open tag of a void element exceeds max_line_length" do
        let(:max_line_length) { 20 }
        let(:source) { '<input type="text" name="email">' }

        it "renders each attribute on its own indented line with />" do
          expect(subject).to eq(<<~ERB.chomp)
            <input
              type="text"
              name="email"
            />
          ERB
        end
      end

      context "when open tag of a nested element exceeds max_line_length" do
        let(:max_line_length) { 20 }
        let(:source) { '<section><div class="foo" id="bar"></div></section>' }

        it "applies correct indentation to multiline attributes within the nested context" do
          expect(subject).to eq(<<~ERB.chomp)
            <section>
              <div
                class="foo"
                id="bar"
              >
              </div>
            </section>
          ERB
        end
      end

      context "with ERB expression node directly in open tag" do
        let(:max_line_length) { 20 }
        let(:source) { '<div class="foo" id="bar" <%= dynamic_attr %>></div>' }

        it "visits ERB expression nodes within multiline attribute rendering" do
          expect(subject).to eq(<<~ERB.chomp)
            <div
              class="foo"
              id="bar"
              <%= dynamic_attr %>
            >
            </div>
          ERB
        end
      end

      context "with herb:disable comment in open tag" do
        let(:max_line_length) { 20 }
        let(:source) { '<div <%# herb:disable rule-name %> class="foo" id="bar">content</div>' }

        it "appends the herb:disable comment inline to the opening line" do
          expect(subject).to eq(<<~ERB.chomp)
            <div <%# herb:disable rule-name %>
              class="foo"
              id="bar"
            >content
            </div>
          ERB
        end
      end

      context "with multiple herb:disable comments in open tag" do
        let(:max_line_length) { 20 }
        let(:source) { '<div <%# herb:disable a %> <%# herb:disable b %> class="foo" id="bar">content</div>' }

        it "appends all herb:disable comments to the opening line" do
          expect(subject).to eq(<<~ERB.chomp)
            <div <%# herb:disable a %> <%# herb:disable b %>
              class="foo"
              id="bar"
            >content
            </div>
          ERB
        end
      end

      context "with herb:disable comment and no other attributes in open tag" do
        let(:source) { "<div\n<%# herb:disable rule-name %>\n<% if condition %>\n<% end %>\n>content</div>" }

        it "appends the herb:disable comment to the opening line with no attribute lines" do
          expect(subject).to eq(<<~ERB.chomp)
            <div <%# herb:disable rule-name %>
              <% if condition %>

              <% end %>
            >content
            </div>
          ERB
        end
      end
    end

    context "with mixed HTML and ERB content" do
      context "with ERB expression inside a div" do
        let(:source) { "<div><%= @user.name %></div>" }

        it "renders ERB inline when it is the only child" do
          expect(subject).to eq("<div><%= @user.name %></div>")
        end
      end
    end

    context "with ERB tags" do
      context "with output tag without spaces" do
        let(:source) { "<%=@user.name%>" }

        it "normalizes spacing" do
          expect(subject).to eq("<%= @user.name %>")
        end
      end

      context "with output tag with extra whitespace" do
        let(:source) { "<%=   @user.name   %>" }

        it "strips extra whitespace" do
          expect(subject).to eq("<%= @user.name %>")
        end
      end

      context "with statement tag without spaces" do
        let(:source) { "<%foo%>" }

        it "normalizes spacing" do
          expect(subject).to eq("<% foo %>")
        end
      end

      context "with whitespace-only content" do
        let(:source) { "<% %>" }

        it "collapses to empty inner content" do
          expect(subject).to eq("<%%>")
        end
      end

      context "with heredoc content" do
        context "with no extra whitespace" do
          let(:source) { "<%=<<HEREDOC\ntext\nHEREDOC\n%>" }

          it "normalizes spacing with newline suffix" do
            expect(subject).to eq("<%= <<HEREDOC\ntext\nHEREDOC\n%>")
          end
        end

        context "with extra spaces around marker" do
          let(:source) { "<%=  <<HEREDOC\ntext\nHEREDOC\n%>" }

          it "strips extra whitespace around marker and uses newline suffix" do
            expect(subject).to eq("<%= <<HEREDOC\ntext\nHEREDOC\n%>")
          end
        end
      end
    end

    context "with text flow" do
      # Text flow (build_and_wrap_text_flow) is invoked from ERB block nodes and HTML
      # element bodies where the content is a mix of text and inline/ERB children.
      # Wiring into HTML element bodies (visit_element_body) is Task 2.35.
      # Basic ERBBlockNode text flow cases are covered in format_printer_erb_visitors_spec.rb.

      context "with ERB block containing text and multiple inline elements" do
        let(:source) { "<% items.each do |item| %>Click <a>here</a> or <a>there</a>.<% end %>" }

        it "flows all inline content onto one line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              Click <a>here</a> or <a>there</a>.
            <% end %>
          EXPECTED
        end
      end

      context "with ERB block where text flow wraps due to max_line_length" do
        let(:max_line_length) { 40 }
        let(:source) do
          "<% items.each do |item| %>The quick brown fox jumps over <strong>the lazy dog</strong><% end %>"
        end

        it "wraps long flow content at word boundaries" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              The quick brown fox jumps over
              <strong>the lazy dog</strong>
            <% end %>
          EXPECTED
        end
      end

      context "with ERB block where flow text has extra whitespace" do
        let(:source) { "<% items.each do |item| %>Hello   <%= item %>   world<% end %>" }

        it "normalizes multiple spaces between words" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              Hello <%= item %> world
            <% end %>
          EXPECTED
        end
      end

      context "with ERB block where an ERB expression causes wrapping" do
        # ERB expressions are atomic (is_atomic: true): they are never split across lines.
        # When adding the expression would exceed wrap_width, the whole expression
        # moves to the next line as a single unit.
        let(:max_line_length) { 30 }
        let(:source) { "<% items.each do |item| %>See <%= very_long_variable_name %><% end %>" }

        it "wraps the entire ERB expression as a single unit onto the next line" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              See
              <%= very_long_variable_name %>
            <% end %>
          EXPECTED
        end
      end

      context "with ERB block containing a herb:disable comment" do
        # herb:disable comments (is_herb_disable: true) are never used as wrap points.
        # They stay appended to the preceding content even if the line exceeds max_line_length.
        let(:max_line_length) { 40 }
        let(:source) { "<% items.each do |item| %>Hello world <%# herb:disable rule-name %><% end %>" }

        it "keeps the herb:disable comment on the same line without wrapping" do
          expect(subject).to eq(<<~EXPECTED.chomp)
            <% items.each do |item| %>
              Hello world <%# herb:disable rule-name %>
            <% end %>
          EXPECTED
        end
      end

      context "with HTML element containing only text" do
        let(:source) { "<p>This is a fairly long line of text that wraps</p>" }

        it { is_expected.to include("This is a fairly long line of text that wraps") }
      end

      context "with HTML element containing inline elements" do
        let(:source) { "<p>Hello <strong>world</strong> today</p>" }

        it { is_expected.to eq("<p>Hello <strong>world</strong> today</p>") }
      end

      context "with HTML element containing ERB content" do
        let(:source) { "<p>Hello <%= @name %></p>" }

        it { is_expected.to eq("<p>Hello <%= @name %></p>") }
      end
    end

    context "with element children" do
      # visit_element_children is currently called from visit_erb_block_node.
      # Tests use ERB block nodes to exercise this path.
      # Sibling spacing (should_add_spacing_between_siblings?) integration tests
      # are deferred to Task 2.36.

      context "with whitespace nodes" do
        context "when body has only whitespace around content" do
          let(:source) { "<% foo.each do |x| %>   \n   <p>content</p>   \n   <% end %>" }

          it "strips surrounding whitespace-only nodes" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% foo.each do |x| %>
                <p>content</p>
              <% end %>
            EXPECTED
          end
        end

        context "when whitespace contains a double newline" do
          let(:source) { "<% foo.each do |x| %><p>first</p>\n\n<p>second</p><% end %>" }

          it "preserves the blank line between elements" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% foo.each do |x| %>
                <p>first</p>

                <p>second</p>
              <% end %>
            EXPECTED
          end
        end

        context "when whitespace contains a single newline" do
          let(:source) { "<% foo.each do |x| %><p>first</p>\n<p>second</p><% end %>" }

          it "does not insert a blank line for a single newline" do
            expect(subject).to eq(<<~EXPECTED.chomp)
              <% foo.each do |x| %>
                <p>first</p>
                <p>second</p>
              <% end %>
            EXPECTED
          end
        end
      end
    end
  end
end
