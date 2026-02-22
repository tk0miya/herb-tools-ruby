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
      context "with simple elements" do
        context "with text content" do
          let(:source) { "<div>Hello</div>" }

          it "outputs opening tag, text content, and closing tag" do
            expect(subject).to eq("<div>Hello</div>")
          end
        end

        context "with basic content" do
          let(:source) { "<div>content</div>" }

          it "outputs opening tag, content, and closing tag" do
            expect(subject).to eq("<div>content</div>")
          end
        end
      end

      context "with void elements" do
        let(:source) { "<br>" }

        it "outputs void element without closing tag" do
          expect(subject).to eq("<br>")
        end
      end

      context "with nested elements" do
        let(:source) { "<div><p>nested</p></div>" }

        it "outputs both opening and closing tags for nested elements" do
          expect(subject).to eq("<div><p>nested</p></div>")
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
              "    <div class=\"\n  flex items-center justify-between px-4 py-2 bg-white\n  shadow-md\n\">content</div>"
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
    end

    context "with mixed HTML and ERB content" do
      context "with ERB expression inside a div" do
        let(:source) { "<div><%= @user.name %></div>" }

        it "renders HTML tags and ERB in a unified output" do
          expect(subject).to eq("<div>\n  <%= @user.name %></div>")
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
      pending "Part F: Text Flow & Spacing (Task 2.29-2.34)"
    end
  end
end
