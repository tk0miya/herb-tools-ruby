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

      it { is_expected.to eq(source) }
    end

    context "when input has a double-quoted attribute" do
      let(:source) { '<div class="container">text</div>' }

      it { is_expected.to eq(source) }
    end

    context "when input has a single-quoted attribute" do
      let(:source) { "<div class='single-quoted'>text</div>" }

      it { is_expected.to eq(source) }
    end

    context "when input has a boolean attribute" do
      let(:source) { '<input type="text" disabled>' }

      it { is_expected.to eq(source) }
    end

    context "when input has multiple attributes" do
      let(:source) { '<div id="main" class="wrapper" data-value="123">text</div>' }

      it { is_expected.to eq(source) }
    end

    context "when attribute has spaces around equals" do
      let(:source) { '<div class = "spaced">text</div>' }

      it { is_expected.to eq(source) }
    end
  end
end
