# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::Context do
  let(:file_path) { "test.html.erb" }
  let(:source) { "line 1\nline 2\nline 3\n" }
  let(:config) do
    Herb::Config::FormatterConfig.new(
      "formatter" => {
        "indentWidth" => 4,
        "maxLineLength" => 120
      }
    )
  end
  let(:context) { described_class.new(file_path:, source:, config:) }

  describe "#indent_width" do
    it "delegates to config" do
      expect(context.indent_width).to eq(4)
    end
  end

  describe "#max_line_length" do
    it "delegates to config" do
      expect(context.max_line_length).to eq(120)
    end
  end

  describe "#source_line" do
    it "returns correct line (1-indexed)" do
      expect(context.source_line(1)).to eq("line 1\n")
      expect(context.source_line(2)).to eq("line 2\n")
      expect(context.source_line(3)).to eq("line 3\n")
    end

    it "returns empty string for out-of-bounds line" do
      expect(context.source_line(0)).to eq("")
      expect(context.source_line(4)).to eq("")
      expect(context.source_line(100)).to eq("")
    end
  end

  describe "#line_count" do
    it "returns correct count" do
      expect(context.line_count).to eq(3)
    end

    context "with empty source" do
      let(:source) { "" }

      it "returns 0" do
        expect(context.line_count).to eq(0)
      end
    end

    context "with single line no newline" do
      let(:source) { "single line" }

      it "returns 1" do
        expect(context.line_count).to eq(1)
      end
    end
  end
end
