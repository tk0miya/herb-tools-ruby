# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::AggregatedResult do
  let(:unchanged_result) do
    Herb::Format::FormatResult.new(
      file_path: "unchanged.html.erb",
      original: "<div>test</div>",
      formatted: "<div>test</div>"
    )
  end

  let(:changed_result) do
    Herb::Format::FormatResult.new(
      file_path: "changed.html.erb",
      original: "<div>test</div>",
      formatted: "<div>\n  test\n</div>"
    )
  end

  let(:ignored_result) do
    Herb::Format::FormatResult.new(
      file_path: "ignored.html.erb",
      original: "<div>test</div>",
      formatted: "<div>test</div>",
      ignored: true
    )
  end

  let(:error_result) do
    Herb::Format::FormatResult.new(
      file_path: "error.html.erb",
      original: "<div>test</div>",
      formatted: "<div>test</div>",
      error: StandardError.new("Parse error")
    )
  end

  describe "#initialize" do
    it "creates an AggregatedResult with an empty array" do
      result = described_class.new(results: [])

      expect(result.results).to eq([])
    end

    it "creates an AggregatedResult with multiple results" do
      results = [unchanged_result, changed_result]
      aggregated = described_class.new(results:)

      expect(aggregated.results).to eq(results)
      expect(aggregated.results.size).to eq(2)
    end
  end

  describe "#file_count" do
    subject { aggregated.file_count }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it { is_expected.to eq(0) }
    end

    context "with one result" do
      let(:aggregated) { described_class.new(results: [unchanged_result]) }

      it { is_expected.to eq(1) }
    end

    context "with multiple results" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, changed_result, ignored_result, error_result])
      end

      it { is_expected.to eq(4) }
    end
  end

  describe "#changed_count" do
    subject { aggregated.changed_count }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it { is_expected.to eq(0) }
    end

    context "with no changed files" do
      let(:aggregated) { described_class.new(results: [unchanged_result, ignored_result]) }

      it { is_expected.to eq(0) }
    end

    context "with some changed files" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, changed_result, ignored_result])
      end

      it { is_expected.to eq(1) }
    end

    context "with all changed files" do
      let(:aggregated) { described_class.new(results: [changed_result, changed_result]) }

      it { is_expected.to eq(2) }
    end
  end

  describe "#ignored_count" do
    subject { aggregated.ignored_count }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it { is_expected.to eq(0) }
    end

    context "with no ignored files" do
      let(:aggregated) { described_class.new(results: [unchanged_result, changed_result]) }

      it { is_expected.to eq(0) }
    end

    context "with some ignored files" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, ignored_result, changed_result])
      end

      it { is_expected.to eq(1) }
    end

    context "with multiple ignored files" do
      let(:aggregated) { described_class.new(results: [ignored_result, ignored_result]) }

      it { is_expected.to eq(2) }
    end
  end

  describe "#error_count" do
    subject { aggregated.error_count }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it { is_expected.to eq(0) }
    end

    context "with no errors" do
      let(:aggregated) { described_class.new(results: [unchanged_result, changed_result, ignored_result]) }

      it { is_expected.to eq(0) }
    end

    context "with some errors" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, error_result, changed_result])
      end

      it { is_expected.to eq(1) }
    end

    context "with multiple errors" do
      let(:aggregated) { described_class.new(results: [error_result, error_result]) }

      it { is_expected.to eq(2) }
    end
  end

  describe "#all_formatted?" do
    subject { aggregated.all_formatted? }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it "returns true (no work needed)" do
        expect(subject).to be(true)
      end
    end

    context "with all files unchanged and no errors" do
      let(:aggregated) { described_class.new(results: [unchanged_result, unchanged_result]) }

      it { is_expected.to be(true) }
    end

    context "with ignored files but no changes or errors" do
      let(:aggregated) { described_class.new(results: [unchanged_result, ignored_result]) }

      it "returns true (ignored files don't affect formatting status)" do
        expect(subject).to be(true)
      end
    end

    context "with some changed files" do
      let(:aggregated) { described_class.new(results: [unchanged_result, changed_result]) }

      it { is_expected.to be(false) }
    end

    context "with some errors" do
      let(:aggregated) { described_class.new(results: [unchanged_result, error_result]) }

      it { is_expected.to be(false) }
    end

    context "with both changes and errors" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, changed_result, error_result])
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#to_h" do
    subject { aggregated.to_h }

    context "with empty results" do
      let(:aggregated) { described_class.new(results: []) }

      it "serializes correctly" do
        expect(subject).to eq({
                                file_count: 0,
                                changed_count: 0,
                                ignored_count: 0,
                                error_count: 0,
                                all_formatted: true
                              })
      end
    end

    context "with all unchanged files" do
      let(:aggregated) { described_class.new(results: [unchanged_result]) }

      it "serializes correctly" do
        expect(subject).to eq({
                                file_count: 1,
                                changed_count: 0,
                                ignored_count: 0,
                                error_count: 0,
                                all_formatted: true
                              })
      end
    end

    context "with mixed results" do
      let(:aggregated) do
        described_class.new(results: [unchanged_result, changed_result, ignored_result, error_result])
      end

      it "serializes correctly" do
        expect(subject).to eq({
                                file_count: 4,
                                changed_count: 1,
                                ignored_count: 1,
                                error_count: 1,
                                all_formatted: false
                              })
      end
    end

    context "with only ignored files" do
      let(:aggregated) { described_class.new(results: [ignored_result, ignored_result]) }

      it "serializes correctly" do
        expect(subject).to eq({
                                file_count: 2,
                                changed_count: 0,
                                ignored_count: 2,
                                error_count: 0,
                                all_formatted: true
                              })
      end
    end

    context "with only errors" do
      let(:aggregated) { described_class.new(results: [error_result]) }

      it "serializes correctly" do
        expect(subject).to eq({
                                file_count: 1,
                                changed_count: 0,
                                ignored_count: 0,
                                error_count: 1,
                                all_formatted: false
                              })
      end
    end
  end
end
