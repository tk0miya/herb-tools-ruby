# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::ElementAnalyzer do
  let(:printer) { build(:format_printer) }
  let(:analyzer) { described_class.new(printer, printer.max_line_length, printer.indent_width) }

  def parse_element(source)
    Herb.parse(source, track_whitespace: true).value.child_nodes.first
  end

  describe "#analyze" do
    subject { analyzer.analyze(element) }

    # -------------------------------------------------------------------------
    # Content-preserving elements → always block
    # -------------------------------------------------------------------------

    context "with a content-preserving element (script)" do
      let(:element) { parse_element("<script>alert('hi')</script>") }

      it "returns block analysis" do
        expect(subject.open_tag_inline).to be(false)
        expect(subject.element_content_inline).to be(false)
        expect(subject.close_tag_inline).to be(false)
      end

      it { is_expected.to be_block_format }
      it { is_expected.not_to be_fully_inline }
    end

    context "with a content-preserving element (pre)" do
      let(:element) { parse_element("<pre>  indented</pre>") }

      it "returns block analysis" do
        expect(subject.open_tag_inline).to be(false)
        expect(subject.element_content_inline).to be(false)
        expect(subject.close_tag_inline).to be(false)
      end
    end

    # -------------------------------------------------------------------------
    # Void elements → always fully inline
    # -------------------------------------------------------------------------

    context "with a void element (br)" do
      let(:element) { parse_element("<br>") }

      it "returns fully inline analysis" do
        expect(subject.open_tag_inline).to be(true)
        expect(subject.element_content_inline).to be(true)
        expect(subject.close_tag_inline).to be(true)
      end

      it { is_expected.to be_fully_inline }
    end

    context "with a void element (img)" do
      let(:element) { parse_element('<img src="foo.png">') }

      it "returns fully inline analysis" do
        expect(subject.open_tag_inline).to be(true)
        expect(subject.element_content_inline).to be(true)
        expect(subject.close_tag_inline).to be(true)
      end
    end

    # -------------------------------------------------------------------------
    # open_tag_inline: false cases
    # -------------------------------------------------------------------------

    context "when in conditional open tag context" do
      let(:element) { parse_element("<div></div>") }

      before { analyzer.instance_variable_set(:@in_conditional_open_tag_context, true) }

      it "returns block analysis due to conditional context" do
        expect(subject.open_tag_inline).to be(false)
        expect(subject.element_content_inline).to be(false)
        expect(subject.close_tag_inline).to be(false)
      end
    end

    context "with multi-line ERB if control flow in open tag" do
      let(:element) { parse_element("<div\n<% if condition %>\nclass=\"active\"\n<% end %>\n></div>") }

      it { expect(subject.open_tag_inline).to be(false) }
    end

    context "with multi-line ERB unless control flow in open tag" do
      let(:element) { parse_element("<div\n<% unless condition %>\nclass=\"active\"\n<% end %>\n></div>") }

      it { expect(subject.open_tag_inline).to be(false) }
    end

    # -------------------------------------------------------------------------
    # open_tag_inline: true cases
    # -------------------------------------------------------------------------

    context "with a simple element with no attributes" do
      let(:element) { parse_element("<div></div>") }

      it { expect(subject.open_tag_inline).to be(true) }
    end

    context "with a simple element with inline attributes" do
      let(:element) { parse_element('<div class="foo"></div>') }

      it { expect(subject.open_tag_inline).to be(true) }
    end

    context "with single-line ERB if control flow in open tag" do
      let(:element) { parse_element('<div <% if condition %>class="active"<% end %>></div>') }

      it { expect(subject.open_tag_inline).to be(true) }
    end

    context "with ERB content node (non-control-flow) in open tag" do
      let(:element) { parse_element("<div <%= condition %>></div>") }

      it { expect(subject.open_tag_inline).to be(true) }
    end

    # -------------------------------------------------------------------------
    # element_content_inline cases
    # -------------------------------------------------------------------------

    context "with empty body" do
      let(:element) { parse_element("<div></div>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with single text child without newlines" do
      let(:element) { parse_element("<div>Hello</div>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with single text child with newlines" do
      let(:element) { parse_element("<div>Hello\nWorld</div>") }

      it { expect(subject.element_content_inline).to be(false) }
    end

    context "with a block-level child element" do
      let(:element) { parse_element("<div><p>nested</p></div>") }

      it { expect(subject.element_content_inline).to be(false) }
    end

    context "with all inline child elements" do
      let(:element) { parse_element("<div><span>one</span><span>two</span></div>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with mixed text and inline content" do
      let(:element) { parse_element("<div>Hello <em>world</em>!</div>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with ERB control flow child" do
      let(:element) { parse_element("<div><% if true %>text<% end %></div>") }

      it { expect(subject.element_content_inline).to be(false) }
    end

    context "with simple ERB content child" do
      let(:element) { parse_element("<div><%= value %></div>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with inline element tag (capture path)" do
      let(:element) { parse_element("<span>Hello</span>") }

      it { expect(subject.element_content_inline).to be(true) }
    end

    context "with inline direct children containing nested block content" do
      let(:element) { parse_element("<div><span><p>deep block</p></span></div>") }

      it { expect(subject.element_content_inline).to be(false) }
    end

    # TODO: Enable once visit methods use push instead of write.
    # Currently capture { visit(element) } returns [] because visit methods
    # write to PrintContext, not @lines. So rendered length is always 0,
    # meaning inline elements are unconditionally treated as fitting.
    # See: Task 2.35 (Wire Up All Components)
    context "with inline element that exceeds max line length",
            skip: "Enable once visit methods use push instead of write (Task 2.35)" do
      let(:analyzer) { described_class.new(printer, 10, printer.indent_width) }
      let(:element) { parse_element("<span>This is a very long text that exceeds the line limit</span>") }

      it { expect(subject.element_content_inline).to be(false) }
    end
  end
end
