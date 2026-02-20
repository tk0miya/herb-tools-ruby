# frozen_string_literal: true

RSpec.describe Herb::Lint::AggregatedResult do
  describe "#initialize" do
    subject { described_class.new(results, rule_count:) }

    let(:results) { [] }
    let(:rule_count) { 0 }

    it "sets the results attribute" do
      expect(subject.results).to eq([])
    end

    it "sets the rule_count attribute" do
      expect(subject.rule_count).to eq(0)
    end

    context "with a custom rule count" do
      let(:rule_count) { 42 }

      it "sets the rule_count to the provided value" do
        expect(subject.rule_count).to eq(42)
      end
    end
  end

  describe "#start_time" do
    subject { described_class.new(results, start_time:) }

    let(:results) { [] }

    context "when start_time is not provided" do
      let(:start_time) { nil }

      it "defaults to nil" do
        expect(subject.start_time).to be_nil
      end
    end

    context "when start_time is provided" do
      let(:start_time) { Time.new(2026, 2, 20, 15, 30, 45) }

      it "stores the start_time value" do
        expect(subject.start_time).to eq(start_time)
      end
    end
  end

  describe "#duration" do
    subject { described_class.new(results, duration:) }

    let(:results) { [] }

    context "when duration is not provided" do
      let(:duration) { nil }

      it "defaults to nil" do
        expect(subject.duration).to be_nil
      end
    end

    context "when duration is provided" do
      let(:duration) { 1234 }

      it "stores the duration in milliseconds" do
        expect(subject.duration).to eq(1234)
      end
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

  describe "#unfixed_offenses" do
    subject { aggregated_result.unfixed_offenses }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when there are multiple results with offenses" do
      let(:error_unfixed_offense) { build(:offense, severity: "error") }
      let(:warning_unfixed_offense) { build(:offense, severity: "warning") }
      let(:info_unfixed_offense) { build(:offense, severity: "info") }

      let(:results) do
        [
          build(:lint_result, unfixed_offenses: [error_unfixed_offense, warning_unfixed_offense]),
          build(:lint_result, unfixed_offenses: [info_unfixed_offense]),
          build(:lint_result, unfixed_offenses: [])
        ]
      end

      it "returns all offenses flattened" do
        expect(subject).to eq([error_unfixed_offense, warning_unfixed_offense, info_unfixed_offense])
      end

      it "returns the correct number of offenses" do
        expect(subject.size).to eq(3)
      end
    end
  end

  describe "#autofixed_count" do
    subject { aggregated_result.autofixed_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are no autofixed offenses" do
      let(:results) do
        [
          build(:lint_result, autofixed_count: 0),
          build(:lint_result, autofixed_count: 0)
        ]
      end

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are autofixed offenses" do
      let(:results) do
        [
          build(:lint_result, autofixed_count: 2),
          build(:lint_result, autofixed_count: 3),
          build(:lint_result, autofixed_count: 0)
        ]
      end

      it "returns the total autofixed count" do
        expect(subject).to eq(5)
      end
    end
  end

  describe "#autofixable_count" do
    subject { aggregated_result.autofixable_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are no autofixable offenses" do
      let(:results) do
        [
          build(:lint_result, autofixable_count: 0),
          build(:lint_result, autofixable_count: 0)
        ]
      end

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when there are autofixable offenses" do
      let(:results) do
        [
          build(:lint_result, autofixable_count: 1),
          build(:lint_result, autofixable_count: 4),
          build(:lint_result, autofixable_count: 2)
        ]
      end

      it "returns the total autofixable count" do
        expect(subject).to eq(7)
      end
    end
  end

  describe "#files_with_offenses_count" do
    subject { aggregated_result.files_with_offenses_count }

    let(:aggregated_result) { described_class.new(results) }

    context "when there are no results" do
      let(:results) { [] }

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when all files have no offenses" do
      let(:results) do
        [
          build(:lint_result),
          build(:lint_result),
          build(:lint_result)
        ]
      end

      it "returns 0" do
        expect(subject).to eq(0)
      end
    end

    context "when some files have offenses" do
      let(:results) do
        [
          build(:lint_result, error_count: 2, warning_count: 1),
          build(:lint_result),
          build(:lint_result, error_count: 1, warning_count: 0)
        ]
      end

      it "returns the count of files with offenses" do
        expect(subject).to eq(2)
      end
    end

    context "when all files have offenses" do
      let(:results) do
        [
          build(:lint_result, error_count: 1, warning_count: 0),
          build(:lint_result, error_count: 0, warning_count: 2),
          build(:lint_result, error_count: 3, warning_count: 1)
        ]
      end

      it "returns the total file count" do
        expect(subject).to eq(3)
      end
    end
  end
end
