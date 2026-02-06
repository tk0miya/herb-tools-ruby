# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlInputRequireAutocomplete do
  describe ".rule_name" do
    it "returns 'html-input-require-autocomplete'" do
      expect(described_class.rule_name).to eq("html-input-require-autocomplete")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description)
        .to eq("Require autocomplete attribute on input elements that accept text input")
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

    context "when input has autocomplete attribute" do
      let(:source) { '<input type="text" name="email" autocomplete="email">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input type='text' is missing autocomplete" do
      let(:source) { '<input type="text" name="email">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-input-require-autocomplete")
        expect(subject.first.message).to include("autocomplete")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when input type='checkbox' is missing autocomplete" do
      let(:source) { '<input type="checkbox" name="agree">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input has no type attribute" do
      let(:source) { '<input name="data">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when input type is uppercase" do
      let(:source) { '<input type="TEXT" name="email">' }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
      end
    end

    context "when INPUT tag is uppercase" do
      let(:source) { '<INPUT type="text" name="email">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when autocomplete attribute is uppercase" do
      let(:source) { '<input type="text" name="email" AUTOCOMPLETE="email">' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when multiple inputs are missing autocomplete" do
      let(:source) { '<input type="text" name="first"><input type="email" name="email">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-input-require-autocomplete"))
      end
    end

    context "with non-input elements" do
      let(:source) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed inputs on multiple lines" do
      let(:source) do
        <<~HTML
          <input type="text" name="first" autocomplete="given-name">
          <input type="email" name="email">
          <input type="checkbox" name="agree">
        HTML
      end

      it "reports offense only for input without autocomplete with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
