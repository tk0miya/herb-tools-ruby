# frozen_string_literal: true

RSpec.describe Herb::Printer::IdentityPrinter do
  describe ".print" do
    subject { described_class.print(parse_result) }

    let(:parse_result) { Herb.parse(source) }

    context "when input is plain text" do
      let(:source) { "Hello, world!" }

      it { is_expected.to eq(source) }
    end

    context "when input is whitespace only" do
      let(:source) { "  \n  " }

      it { is_expected.to eq(source) }
    end
  end
end
