# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoDuplicateMetaNames do
  describe ".rule_name" do
    it "returns 'html-no-duplicate-meta-names'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-meta-names")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate meta elements with the same name attribute")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when all meta names are unique" do
      let(:source) do
        <<~HTML
          <meta name="description" content="Page description">
          <meta name="viewport" content="width=device-width">
          <meta name="author" content="John">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are duplicate meta names" do
      let(:source) do
        <<~HTML
          <meta name="description" content="First">
          <meta name="description" content="Second">
        HTML
      end

      it "reports an offense for the duplicate with first occurrence line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to include("Duplicate meta name 'description'")
        expect(subject.first.message).to include("first defined at line 1")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when the same meta name appears three times" do
      let(:source) do
        <<~HTML
          <meta name="description" content="First">
          <meta name="description" content="Second">
          <meta name="description" content="Third">
        HTML
      end

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include("Duplicate meta name 'description'"))
      end
    end

    context "when meta elements have no name attribute" do
      let(:source) do
        <<~HTML
          <meta charset="utf-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when meta name attribute has empty value" do
      let(:source) do
        <<~HTML
          <meta name="" content="First">
          <meta name="" content="Second">
        HTML
      end

      it "does not report an offense (empty names are not tracked)" do
        expect(subject).to be_empty
      end
    end

    context "when meta names differ only in case" do
      let(:source) do
        <<~HTML
          <meta name="Description" content="First">
          <meta name="description" content="Second">
        HTML
      end

      it "reports an offense (case-insensitive comparison)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Duplicate meta name 'description'")
      end
    end

    context "when non-meta elements have the same name attribute" do
      let(:source) do
        <<~HTML
          <input name="email" type="text">
          <input name="email" type="hidden">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with a mix of meta and non-meta elements" do
      let(:source) do
        <<~HTML
          <meta name="description" content="Page">
          <input name="description" type="text">
          <meta name="viewport" content="width=device-width">
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with a single meta element" do
      let(:source) { '<meta name="description" content="Page">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested meta elements in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="First">
            <title>Page</title>
            <meta name="description" content="Second">
          </head>
        HTML
      end

      it "reports an offense for the nested duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Duplicate meta name 'description'")
        expect(subject.first.line).to eq(4)
      end
    end
  end
end
