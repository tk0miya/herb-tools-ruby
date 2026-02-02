# frozen_string_literal: true

RSpec.describe Herb::Printer::IdentityPrinter do
  describe ".print" do
    subject { described_class.print(parse_result) }

    let(:parse_result) { Herb.parse(source, track_whitespace: true) }

    context "when input is plain text" do
      let(:source) { "Hello, world!" }

      it { is_expected.to eq(source) }
    end

    context "when input is whitespace only" do
      let(:source) { "  \n  " }

      it { is_expected.to eq(source) }
    end

    context "when input is a simple element" do
      let(:source) { "<div></div>" }

      it { is_expected.to eq(source) }
    end

    context "when input is an element with text content" do
      let(:source) { "<div>Hello</div>" }

      it { is_expected.to eq(source) }
    end

    context "when open tag contains trailing space" do
      let(:source) { "<div >text</div>" }

      it { is_expected.to eq(source) }
    end

    context "when close tag contains spaces" do
      let(:source) { "<div></ div >" }

      it { is_expected.to eq(source) }
    end

    context "when input is a void element" do
      let(:source) { "<br>" }

      it { is_expected.to eq(source) }
    end

    context "when input is a void element with attribute" do
      let(:source) { '<img src="photo.jpg">' }

      # Requires attribute visitors (Task 14.7)
      it(nil, pending: "attribute visitors not yet implemented") { is_expected.to eq(source) }
    end
  end
end
