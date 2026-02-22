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

        it "formats nested block elements on separate lines with indentation" do
          expect(subject).to eq("<div>\n  <p>nested</p>\n</div>")
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

      context "with multiline attributes" do
        context "with multiple attributes" do
          let(:max_line_length) { 30 }
          let(:source) { '<button type="submit" class="btn" disabled></button>' }

          it "outputs tag name, each attribute indented, and closing >" do
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

        context "with void element" do
          let(:max_line_length) { 25 }
          let(:source) { '<input type="text" name="email">' }

          it "renders inline regardless of max_line_length (void elements always inline)" do
            expect(subject).to eq('<input type="text" name="email">')
          end
        end

        context "with indented context" do
          let(:max_line_length) { 20 }
          let(:source) { '<div><div class="foo" id="bar"></div></div>' }

          it "applies current indent to all lines" do
            expect(subject).to eq(<<~ERB.chomp)
              <div>
                <div
                  class="foo"
                  id="bar"
                >
                </div>
              </div>
            ERB
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
    end

    context "with ERB tags" do
      pending "Part E: ERB Formatting (Task 2.22-2.28)"
    end

    context "with text flow" do
      pending "Part F: Text Flow & Spacing (Task 2.29-2.34)"
    end
  end

  describe "#current_element" do
    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    it "returns nil when no element is being visited" do
      expect(printer.current_element).to be_nil
    end

    it "returns the enclosing HTMLElementNode during visit" do
      source = "<div>text</div>"
      ast = Herb.parse(source, track_whitespace: true)
      element = ast.value.children.first

      observed = nil
      allow(printer).to receive(:visit_html_open_tag_node).and_wrap_original do |original, node|
        observed = printer.current_element
        original.call(node)
      end

      printer.visit(ast.value)

      expect(observed).to equal(element)
    end
  end

  describe "#visit_html_element_node" do
    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    it "pushes @element_stack before visit(open_tag) and pops after" do
      source = "<div>text</div>"
      ast = Herb.parse(source, track_whitespace: true)
      element = ast.value.children.first

      stack_depth_during_open_tag = nil
      allow(printer).to receive(:visit_html_open_tag_node).and_wrap_original do |original, node|
        stack_depth_during_open_tag = printer.current_element
        original.call(node)
      end

      printer.visit(ast.value)

      expect(stack_depth_during_open_tag).to equal(element)
      expect(printer.current_element).to be_nil
    end
  end

  describe "#visit_html_open_tag_node" do
    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    it "dispatches to inline rendering when open_tag_inline is true" do
      source = "<div>text</div>"
      result = described_class.format(Herb.parse(source, track_whitespace: true), format_context:)

      expect(result).to eq("<div>text</div>")
    end

    it "dispatches to multiline rendering when open_tag_inline is false" do
      source = "<pre>content</pre>"
      result = described_class.format(Herb.parse(source, track_whitespace: true), format_context:)

      # content_preserving elements use open_tag_inline: false
      # but with no attributes, the open tag is still rendered as single line
      expect(result).to include("<pre>")
    end
  end

  describe "#visit_html_close_tag_node" do
    let(:printer) do
      described_class.new(indent_width:, max_line_length:, format_context:)
    end

    it "appends close tag inline when close_tag_inline is true" do
      source = "<div>text</div>"
      result = described_class.format(Herb.parse(source, track_whitespace: true), format_context:)

      expect(result).to eq("<div>text</div>")
    end

    it "puts close tag on a new line when close_tag_inline is false" do
      source = "<div><p>nested</p></div>"
      result = described_class.format(Herb.parse(source, track_whitespace: true), format_context:)

      expect(result).to eq("<div>\n  <p>nested</p>\n</div>")
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

  describe "#print_erb_node" do
    subject { printer.capture { printer.send(:print_erb_node, node) } }

    let(:printer) do
      Class.new(described_class) do
        attr_accessor :inline_mode, :indent_level
      end.new(indent_width:, max_line_length:, format_context:)
    end

    context "when not in inline mode" do
      context "with output tag" do
        let(:node) { Herb.parse("<%=@user.name%>").value.children.first }

        it "normalizes spacing" do
          expect(subject).to eq(["<%= @user.name %>"])
        end

        context "with extra whitespace in content" do
          let(:node) { Herb.parse("<%=   @user.name   %>").value.children.first }

          it "strips extra whitespace" do
            expect(subject).to eq(["<%= @user.name %>"])
          end
        end

        context "with indentation" do
          before { printer.indent_level = 1 }

          it "pushes with current indentation" do
            expect(subject).to eq(["  <%= @user.name %>"])
          end
        end
      end

      context "with statement tag" do
        let(:node) { Herb.parse("<%foo%>").value.children.first }

        it "normalizes spacing" do
          expect(subject).to eq(["<% foo %>"])
        end
      end

      context "with whitespace-only content" do
        let(:node) { Herb.parse("<% %>").value.children.first }

        it "collapses to empty inner content" do
          expect(subject).to eq(["<%%>"])
        end
      end

      describe "heredoc content" do
        context "with no extra whitespace" do
          let(:node) { Herb.parse("<%=<<HEREDOC\ntext\nHEREDOC\n%>").value.children.first }

          it "normalizes spacing and uses newline suffix" do
            expect(subject).to eq(["<%= <<HEREDOC\ntext\nHEREDOC\n%>"])
          end
        end

        context "with extra spaces around marker" do
          let(:node) { Herb.parse("<%=  <<HEREDOC\ntext\nHEREDOC\n%>").value.children.first }

          it "strips extra whitespace around marker and uses newline suffix" do
            expect(subject).to eq(["<%= <<HEREDOC\ntext\nHEREDOC\n%>"])
          end
        end
      end
    end

    context "when in inline mode" do
      let(:node) { Herb.parse("<%=@user.name%>").value.children.first }

      before { printer.inline_mode = true }

      it "pushes the ERB tag without any indentation" do
        expect(subject).to eq(["<%= @user.name %>"])
      end

      context "with indent level set" do
        before { printer.indent_level = 2 }

        it "ignores indent level and pushes without indentation" do
          expect(subject).to eq(["<%= @user.name %>"])
        end
      end
    end
  end
end
