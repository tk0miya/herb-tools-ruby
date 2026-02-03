# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ParserNoErrors do
  describe ".rule_name" do
    it "returns 'parser-no-errors'" do
      expect(described_class.rule_name).to eq("parser-no-errors")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Report parser errors as lint offenses")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(template, track_whitespace: true) }
    let(:context) { build(:context) }
    let(:template) { "<div>Hello</div>" }

    it "returns empty array (parser errors are handled by Linter)" do
      expect(subject).to be_empty
    end
  end
end
