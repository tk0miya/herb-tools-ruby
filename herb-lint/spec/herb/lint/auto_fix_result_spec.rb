# frozen_string_literal: true

RSpec.describe Herb::Lint::AutoFixResult do
  describe "#fixed_count" do
    subject { described_class.new(source: "", fixed:, unfixed: []).fixed_count }

    context "when there are fixed offenses" do
      let(:fixed) { build_list(:offense, 2) }

      it { is_expected.to eq(2) }
    end

    context "when there are no fixed offenses" do
      let(:fixed) { [] }

      it { is_expected.to eq(0) }
    end
  end

  describe "#unfixed_count" do
    subject { described_class.new(source: "", fixed: [], unfixed:).unfixed_count }

    context "when there are unfixed offenses" do
      let(:unfixed) { build_list(:offense, 3) }

      it { is_expected.to eq(3) }
    end

    context "when there are no unfixed offenses" do
      let(:unfixed) { [] }

      it { is_expected.to eq(0) }
    end
  end
end
