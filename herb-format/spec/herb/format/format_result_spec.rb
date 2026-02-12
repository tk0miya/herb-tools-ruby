# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::FormatResult do
  describe "#initialize" do
    it "creates a FormatResult with required fields" do
      result = described_class.new(
        file_path: "test.html.erb",
        original: "<div>test</div>",
        formatted: "<div>test</div>"
      )

      expect(result.file_path).to eq("test.html.erb")
      expect(result.original).to eq("<div>test</div>")
      expect(result.formatted).to eq("<div>test</div>")
      expect(result.ignored).to be(false)
      expect(result.error).to be_nil
    end

    it "accepts optional ignored and error parameters" do
      error = StandardError.new("Parse error")
      result = described_class.new(
        file_path: "test.html.erb",
        original: "<div>test</div>",
        formatted: "<div>test</div>",
        ignored: true,
        error:
      )

      expect(result.ignored).to be(true)
      expect(result.error).to eq(error)
    end
  end

  describe "#ignored?" do
    subject { result.ignored? }

    context "when not ignored" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>"
        )
      end

      it { is_expected.to be(false) }
    end

    context "when ignored" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>",
          ignored: true
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#error?" do
    subject { result.error? }

    context "when no error" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>"
        )
      end

      it { is_expected.to be(false) }
    end

    context "when error is present" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>",
          error: StandardError.new("Parse error")
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#changed?" do
    subject { result.changed? }

    context "when original equals formatted" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>"
        )
      end

      it { is_expected.to be(false) }
    end

    context "when original differs from formatted" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>\n  test\n</div>"
        )
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#diff" do
    subject { result.diff }

    context "when there are no changes" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>"
        )
      end

      it { is_expected.to be_nil }
    end

    context "when there are changes" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>\n",
          formatted: "<div>\n  test\n</div>\n"
        )
      end

      it "returns a unified diff string" do
        expect(subject).not_to be_nil
        expect(subject).to include("---")
        expect(subject).to include("+++")
        expect(subject).to include("test.html.erb")
      end
    end
  end

  describe "#to_h" do
    subject { result.to_h }

    context "with no changes" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>"
        )
      end

      it "serializes to hash correctly" do
        expect(subject).to eq({
                                file_path: "test.html.erb",
                                changed: false,
                                ignored: false,
                                error: nil
                              })
      end
    end

    context "with changes" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>\n  test\n</div>"
        )
      end

      it "serializes to hash correctly" do
        expect(subject).to eq({
                                file_path: "test.html.erb",
                                changed: true,
                                ignored: false,
                                error: nil
                              })
      end
    end

    context "when ignored" do
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>",
          ignored: true
        )
      end

      it "serializes to hash correctly" do
        expect(subject).to eq({
                                file_path: "test.html.erb",
                                changed: false,
                                ignored: true,
                                error: nil
                              })
      end
    end

    context "with error message" do
      let(:error) { StandardError.new("Parse error") }
      let(:result) do
        described_class.new(
          file_path: "test.html.erb",
          original: "<div>test</div>",
          formatted: "<div>test</div>",
          error:
        )
      end

      it "serializes to hash correctly" do
        expect(subject).to eq({
                                file_path: "test.html.erb",
                                changed: false,
                                ignored: false,
                                error: "Parse error"
                              })
      end
    end

    context "with all fields" do
      let(:error) { StandardError.new("Test error") }
      let(:result) do
        described_class.new(
          file_path: "complex.html.erb",
          original: "original content",
          formatted: "formatted content",
          ignored: true,
          error:
        )
      end

      it "includes all fields correctly" do
        expect(subject[:file_path]).to eq("complex.html.erb")
        expect(subject[:changed]).to be(true)
        expect(subject[:ignored]).to be(true)
        expect(subject[:error]).to eq("Test error")
      end
    end
  end
end
