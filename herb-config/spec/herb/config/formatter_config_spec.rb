# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Config::FormatterConfig do
  describe "#initialize" do
    it "accepts a configuration hash" do
      config_hash = {
        "formatter" => {
          "enabled" => true,
          "indentWidth" => 2
        }
      }
      config = described_class.new(config_hash)

      expect(config.enabled).to be true
      expect(config.indent_width).to eq(2)
    end
  end

  describe "#enabled" do
    subject { described_class.new(config).enabled }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to be false }
    end

    context "when configured as true" do
      let(:config) { { "formatter" => { "enabled" => true } } }

      it { is_expected.to be true }
    end

    context "when configured as false" do
      let(:config) { { "formatter" => { "enabled" => false } } }

      it { is_expected.to be false }
    end
  end

  describe "#include_patterns" do
    subject { described_class.new(config).include_patterns }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq([]) }
    end

    context "when both files.include and formatter.include are configured" do
      let(:config) do
        {
          "files" => { "include" => ["**/*.html.erb"] },
          "formatter" => { "include" => ["**/*.xml.erb"] }
        }
      end

      it "merges patterns from both sections" do
        expect(subject).to eq(["**/*.html.erb", "**/*.xml.erb"])
      end
    end
  end

  describe "#exclude_patterns" do
    subject { described_class.new(config).exclude_patterns }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq([]) }
    end

    context "when formatter.exclude is configured" do
      let(:config) do
        {
          "files" => { "exclude" => ["vendor/**/*"] },
          "formatter" => { "exclude" => ["node_modules/**/*"] }
        }
      end

      it "returns formatter.exclude (overrides files.exclude)" do
        expect(subject).to eq(["node_modules/**/*"])
      end
    end

    context "when only files.exclude is configured" do
      let(:config) do
        {
          "files" => { "exclude" => ["vendor/**/*"] }
        }
      end

      it "falls back to files.exclude" do
        expect(subject).to eq(["vendor/**/*"])
      end
    end
  end

  describe "#indent_width" do
    subject { described_class.new(config).indent_width }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq(2) }
    end

    context "when configured" do
      let(:config) { { "formatter" => { "indentWidth" => 4 } } }

      it { is_expected.to eq(4) }
    end
  end

  describe "#max_line_length" do
    subject { described_class.new(config).max_line_length }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq(80) }
    end

    context "when configured" do
      let(:config) { { "formatter" => { "maxLineLength" => 120 } } }

      it { is_expected.to eq(120) }
    end
  end

  describe "#rewriter_pre" do
    subject { described_class.new(config).rewriter_pre }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq([]) }
    end

    context "when configured" do
      let(:config) { { "formatter" => { "rewriter" => { "pre" => ["normalize-attributes"] } } } }

      it { is_expected.to eq(["normalize-attributes"]) }
    end
  end

  describe "#rewriter_post" do
    subject { described_class.new(config).rewriter_post }

    context "when not configured" do
      let(:config) { {} }

      it { is_expected.to eq([]) }
    end

    context "when configured" do
      let(:config) { { "formatter" => { "rewriter" => { "post" => ["tailwind-class-sorter"] } } } }

      it { is_expected.to eq(["tailwind-class-sorter"]) }
    end
  end
end
