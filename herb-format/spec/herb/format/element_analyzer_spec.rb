# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::ElementAnalyzer do
  let(:printer) { build(:format_printer) }
  let(:analyzer) { described_class.new(printer, printer.max_line_length, printer.indent_width) }

  def parse_element(source)
    Herb.parse(source, track_whitespace: true).value.child_nodes.first
  end

  describe "#should_render_open_tag_inline?" do
    subject { analyzer.should_render_open_tag_inline?(element) }

    context "when in conditional open tag context" do
      let(:element) { parse_element("<div></div>") }

      before { analyzer.instance_variable_set(:@in_conditional_open_tag_context, true) }

      it { is_expected.to be(false) }
    end

    context "with a simple element with no attributes" do
      let(:element) { parse_element("<div></div>") }

      it { is_expected.to be(true) }
    end

    context "with a simple element with inline attributes" do
      let(:element) { parse_element('<div class="foo"></div>') }

      it { is_expected.to be(true) }
    end

    context "with multi-line ERB if control flow in open tag" do
      let(:element) { parse_element("<div\n<% if condition %>\nclass=\"active\"\n<% end %>\n></div>") }

      it { is_expected.to be(false) }
    end

    context "with multi-line ERB unless control flow in open tag" do
      let(:element) { parse_element("<div\n<% unless condition %>\nclass=\"active\"\n<% end %>\n></div>") }

      it { is_expected.to be(false) }
    end

    context "with single-line ERB if control flow in open tag" do
      let(:element) { parse_element('<div <% if condition %>class="active"<% end %>></div>') }

      it { is_expected.to be(true) }
    end

    context "with ERB content node (non-control-flow) in open tag" do
      let(:element) { parse_element("<div <%= condition %>></div>") }

      it { is_expected.to be(true) }
    end
  end
end
