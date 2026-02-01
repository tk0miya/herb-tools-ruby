# frozen_string_literal: true

RSpec.describe Herb::Lint::AggregatedResult do
  describe "#initialize" do
    subject { described_class.new(results) }

    let(:results) { [] }

    it "sets the results attribute" do
      expect(subject.results).to eq([])
    end
  end

  describe "#offense_count" do
    subject { aggregated_result.offense_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple results with offenses" do
      let(:results) do
        [
          build(:lint_result, error_count: 2, warning_count: 1),
          build(:lint_result, error_count: 1, warning_count: 3),
          build(:lint_result)
        ]
      end

      it "returns the total count across all files" do
        expect(subject).to eq(7)
      end
    end
  end

  describe "#error_count" do
    subject { aggregated_result.error_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple results" do
      let(:results) do
        [
          build(:lint_result, error_count: 3, warning_count: 1),
          build(:lint_result, error_count: 2, warning_count: 5)
        ]
      end

      it "returns the total error count" do
        expect(subject).to eq(5)
      end
    end
  end

  describe "#warning_count" do
    subject { aggregated_result.warning_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple results" do
      let(:results) do
        [
          build(:lint_result, error_count: 1, warning_count: 4),
          build(:lint_result, error_count: 2, warning_count: 2)
        ]
      end

      it "returns the total warning count" do
        expect(subject).to eq(6)
      end
    end
  end

  describe "#file_count" do
    subject { aggregated_result.file_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are multiple results" do
      let(:results) do
        [
          build(:lint_result, :with_errors),
          build(:lint_result, :with_warnings),
          build(:lint_result)
        ]
      end

      it "returns the number of files" do
        expect(subject).to eq(3)
      end
    end
  end

  describe "#success?" do
    subject { aggregated_result.success? }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no offenses" do
      let(:results) do
        [
          build(:lint_result),
          build(:lint_result)
        ]
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when there are no results" do
      let(:results) { [] }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when there are offenses" do
      let(:results) do
        [
          build(:lint_result),
          build(:lint_result, :with_errors)
        ]
      end

      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
