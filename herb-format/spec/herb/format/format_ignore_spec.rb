# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::FormatIgnore do
  describe ".ignore?" do
    subject { described_class.ignore?(document) }

    let(:document) { Herb.parse(source).value }

    context "when file contains herb:formatter ignore directive" do
      let(:source) { "<%# herb:formatter ignore %>\n<div>test</div>" }

      it { is_expected.to be true }
    end

    context "when file does not contain directive" do
      let(:source) { "<div>test</div>" }

      it { is_expected.to be false }
    end

    context "when file contains other ERB comments" do
      let(:source) { "<%# This is a comment %>\n<div>test</div>" }

      it { is_expected.to be false }
    end

    context "when directive has extra whitespace" do
      let(:source) { "<%#  herb:formatter ignore  %>\n<div>test</div>" }

      it { is_expected.to be true }
    end

    context "when directive is not at the beginning of file" do
      let(:source) { "<div>\n  <%# herb:formatter ignore %>\n</div>" }

      it { is_expected.to be true }
    end

    context "when file contains a non-ignore herb:formatter comment" do
      let(:source) { "<%# herb:formatter something %>\n<div>test</div>" }

      it { is_expected.to be false }
    end
  end

  describe ".ignore_comment?" do
    subject { described_class.ignore_comment?(node) }

    let(:node) { Herb.parse(source).value.child_nodes.first }

    context "when node is a herb:formatter ignore comment" do
      let(:source) { "<%# herb:formatter ignore %>" }

      it { is_expected.to be true }
    end

    context "when node is an ERB comment with different content" do
      let(:source) { "<%# other comment %>" }

      it { is_expected.to be false }
    end

    context "when node is not an ERB comment" do
      let(:source) { "<div>test</div>" }

      it { is_expected.to be false }
    end

    context "when node is an ERB expression (not a comment)" do
      let(:source) { "<%= 'herb:formatter ignore' %>" }

      it { is_expected.to be false }
    end
  end
end
