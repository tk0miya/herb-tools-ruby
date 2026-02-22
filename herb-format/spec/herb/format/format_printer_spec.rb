# frozen_string_literal: true

RSpec.describe Herb::Format::FormatPrinter do
  let(:config) do
    Herb::Config::FormatterConfig.new({
                                        "formatter" => {
                                          "enabled" => true,
                                          "indentWidth" => indent_width,
                                          "maxLineLength" => max_line_length
                                        }
                                      })
  end
  let(:indent_width) { 2 }
  let(:max_line_length) { 80 }
  let(:source) { "" }
  let(:format_context) { Herb::Format::Context.new(file_path: "test.erb", config:, source:) }

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

  describe "#indent_string" do
    subject { printer.send(:indent_string, level) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with level 0" do
      let(:level) { 0 }

      it { is_expected.to eq("") }
    end

    context "with level 1" do
      let(:level) { 1 }

      it { is_expected.to eq("  ") }
    end

    context "with custom indent_width" do
      let(:indent_width) { 4 }
      let(:level) { 1 }

      it { is_expected.to eq("    ") }
    end
  end

  describe "#void_element?" do
    subject { printer.send(:void_element?, tag_name) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with void element" do
      let(:tag_name) { "br" }

      it { is_expected.to be true }
    end

    context "with non-void element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end

    context "with uppercase void element" do
      let(:tag_name) { "BR" }

      it { is_expected.to be true }
    end

    context "with uppercase non-void element" do
      let(:tag_name) { "DIV" }

      it { is_expected.to be false }
    end
  end

  describe "#preserved_element?" do
    subject { printer.send(:preserved_element?, tag_name) }

    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    context "with script tag" do
      let(:tag_name) { "script" }

      it { is_expected.to be true }
    end

    context "with style tag" do
      let(:tag_name) { "style" }

      it { is_expected.to be true }
    end

    context "with pre tag" do
      let(:tag_name) { "pre" }

      it { is_expected.to be true }
    end

    context "with textarea tag" do
      let(:tag_name) { "textarea" }

      it { is_expected.to be true }
    end

    context "with non-preserved element" do
      let(:tag_name) { "div" }

      it { is_expected.to be false }
    end

    context "with uppercase preserved element" do
      let(:tag_name) { "PRE" }

      it { is_expected.to be true }
    end

    context "with uppercase non-preserved element" do
      let(:tag_name) { "DIV" }

      it { is_expected.to be false }
    end
  end

  describe "#push" do
    let(:printer) do
      Class.new(described_class) do
        public :push
        attr_reader :string_line_count
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "appends a line to the capture buffer" do
      result = printer.capture { printer.push("hello") }

      expect(result).to eq(["hello"])
    end

    it "increments string_line_count by 1 when line contains one newline" do
      printer.push("line\n")

      expect(printer.string_line_count).to eq(1)
    end

    it "increments string_line_count by the number of newlines in the string" do
      printer.push("\n\n\n")

      expect(printer.string_line_count).to eq(3)
    end

    it "does not increment string_line_count for lines without newlines" do
      printer.push("no newline")

      expect(printer.string_line_count).to eq(0)
    end
  end

  describe "#indent" do
    subject { printer.send(:indent) }

    let(:printer) do
      Class.new(described_class) do
        public :indent
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with indent_level 0" do
      it { is_expected.to eq("") }
    end

    context "with indent_level 1" do
      before { printer.indent_level = 1 }

      it { is_expected.to eq("  ") }
    end

    context "with indent_level 2" do
      before { printer.indent_level = 2 }

      it { is_expected.to eq("    ") }
    end

    context "with custom indent_width" do
      let(:indent_width) { 4 }

      before { printer.indent_level = 1 }

      it { is_expected.to eq("    ") }
    end
  end

  describe "#push_with_indent" do
    let(:printer) do
      Class.new(described_class) do
        public :push_with_indent
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "with indent_level 0" do
      it "pushes the line without indentation" do
        result = printer.capture { printer.push_with_indent("hello") }

        expect(result).to eq(["hello"])
      end
    end

    context "with indent_level 1" do
      before { printer.indent_level = 1 }

      it "pushes the line with indentation" do
        result = printer.capture { printer.push_with_indent("hello") }

        expect(result).to eq(["  hello"])
      end
    end

    context "with empty line" do
      before { printer.indent_level = 2 }

      it "pushes empty line without indentation" do
        result = printer.capture { printer.push_with_indent("") }

        expect(result).to eq([""])
      end
    end

    context "with whitespace-only line" do
      before { printer.indent_level = 1 }

      it "pushes whitespace-only line without indentation" do
        result = printer.capture { printer.push_with_indent("   ") }

        expect(result).to eq(["   "])
      end
    end
  end

  describe "#push_to_last_line" do
    let(:printer) do
      Class.new(described_class) do
        public :push, :push_to_last_line
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "when buffer is empty" do
      it "starts a new line with the text" do
        result = printer.capture { printer.push_to_last_line("hello") }

        expect(result).to eq(["hello"])
      end
    end

    context "when buffer has lines" do
      it "appends text to the last line without adding a new element" do
        result = printer.capture do
          printer.push("first")
          printer.push_to_last_line(" appended")
        end

        expect(result).to eq(["first appended"])
      end

      it "appends to the last of multiple lines" do
        result = printer.capture do
          printer.push("line1")
          printer.push("line2")
          printer.push_to_last_line(" suffix")
        end

        expect(result).to eq(["line1", "line2 suffix"])
      end
    end
  end

  describe "#render_multiline_attributes" do
    let(:printer) do
      Class.new(described_class) do
        public :render_multiline_attributes
        attr_accessor :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    def open_tag_children(source)
      ast = Herb.parse(source, track_whitespace: true)
      element = ast.value.children.first
      element.open_tag.child_nodes
    end

    context "with multiple attributes" do
      subject { printer.capture { printer.render_multiline_attributes("button", open_tag_children(source), false) } }

      let(:source) { '<button type="submit" class="btn" disabled></button>' }

      it "outputs tag name, each attribute indented, and closing >" do
        expect(subject).to eq(["<button", '  type="submit"', '  class="btn"', "  disabled", ">"])
      end
    end

    context "with void element" do
      subject { printer.capture { printer.render_multiline_attributes("input", open_tag_children(source), true) } }

      let(:source) { '<input type="text" name="email">' }

      it "outputs tag name, each attribute indented, and closing />" do
        expect(subject).to eq(["<input", '  type="text"', '  name="email"', "/>"])
      end
    end

    context "with indented context" do
      subject { printer.capture { printer.render_multiline_attributes("div", open_tag_children(source), false) } }

      let(:source) { '<div class="foo" id="bar"></div>' }

      before { printer.indent_level = 1 }

      it "applies current indent to all lines" do
        expect(subject).to eq(["  <div", '    class="foo"', '    id="bar"', "  >"])
      end
    end

    context "with no children" do
      subject { printer.capture { printer.render_multiline_attributes("div", [], false) } }

      it "outputs tag name and closing > with no attributes" do
        expect(subject).to eq(["<div", ">"])
      end
    end

    context "with only whitespace children" do
      subject { printer.capture { printer.render_multiline_attributes("div", open_tag_children(source), false) } }

      let(:source) { "<div ></div>" }

      it "outputs tag name and closing > skipping whitespace nodes" do
        expect(subject).to eq(["<div", ">"])
      end
    end

    context "with ERB expression tag among children" do
      pending "implement after Task 2.21b (ERB tag rendering in attributes) — tracked in Task 2.21c"
    end

    context "with herb:disable comment in open tag" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with ERB tag in attribute value" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with multiple herb:disable comments" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end

    context "with herb:disable comment and no other attributes" do
      pending "implement after Task 2.28 (ERB Comment Node) — tracked in Task 2.28b"
    end
  end

  describe "#with_indent" do
    let(:printer) do
      Class.new(described_class) do
        public :with_indent
        attr_reader :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "increases indent_level by 1 inside the block" do
      printer.with_indent do
        expect(printer.indent_level).to eq(1)
      end
    end

    it "restores indent_level to 0 after the block" do
      printer.with_indent { nil }

      expect(printer.indent_level).to eq(0)
    end

    it "supports nested with_indent calls" do
      printer.with_indent do
        printer.with_indent do
          expect(printer.indent_level).to eq(2)
        end
        expect(printer.indent_level).to eq(1)
      end
      expect(printer.indent_level).to eq(0)
    end
  end

  describe "#capture" do
    subject { printer.capture { nil } }

    let(:printer) do
      Class.new(described_class) do
        public :push
        attr_reader :string_line_count
        attr_accessor :inline_mode
      end.new(indent_width:, max_line_length:, format_context:)
    end

    it "returns an empty array when block produces no output" do
      expect(subject).to eq([])
    end

    context "with lines pushed inside block" do
      subject { printer.capture { printer.push("hello") } }

      it "captures the pushed lines" do
        expect(subject).to eq(["hello"])
      end
    end

    context "with lines pushed before and inside capture" do
      it "isolates captured output from outer buffer" do
        printer.push("outer")
        result = printer.capture { printer.push("inner") }

        expect(result).to eq(["inner"])
      end

      it "restores the outer buffer after capture" do
        printer.push("outer")
        printer.capture { printer.push("inner") }
        result = printer.capture { printer.push("check") }

        expect(result).to eq(["check"])
      end
    end

    context "with string_line_count incremented inside block" do
      it "restores string_line_count after capture" do
        printer.push("outer\n")
        printer.capture { printer.push("inner\n") }

        expect(printer.string_line_count).to eq(1)
      end
    end

    context "with inline_mode set to true" do
      before { printer.inline_mode = true }

      it "restores inline_mode after capture" do
        printer.capture { nil }

        expect(printer.inline_mode).to be true
      end
    end
  end

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
