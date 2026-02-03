# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbRequireTrailingNewline do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context, source: template) }

  describe ".rule_name" do
    it "returns 'erb-require-trailing-newline'" do
      expect(described_class.rule_name).to eq("erb-require-trailing-newline")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require a trailing newline at the end of the file")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when file ends with a single newline" do
      let(:template) { "<div>content</div>\n" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when file ends with no newline" do
      let(:template) { "<div>content</div>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-trailing-newline")
        expect(subject.first.message).to eq("File must end with a newline")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when file ends with multiple newlines" do
      let(:template) { "<div>content</div>\n\n" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-require-trailing-newline")
        expect(subject.first.message).to eq("File must end with exactly one newline")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when file is empty" do
      let(:template) { "" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
