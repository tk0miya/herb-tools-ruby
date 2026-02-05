# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoSelfClosing do
  describe ".rule_name" do
    it "returns 'html-no-self-closing'" do
      expect(described_class.rule_name).to eq("html-no-self-closing")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Consistent self-closing style for void elements")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when void element has no self-closing slash" do
      let(:source) { "<br>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when void element has self-closing slash" do
      let(:source) { "<br/>" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-self-closing")
        expect(subject.first.message).to eq("Void element 'br' should not have a self-closing slash")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when void element has self-closing slash with space" do
      let(:source) { "<br />" }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Void element 'br' should not have a self-closing slash")
      end
    end

    context "when void element with attributes has self-closing slash" do
      let(:source) { '<img src="photo.jpg" />' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Void element 'img' should not have a self-closing slash")
      end
    end

    context "when non-void element has closing tag" do
      let(:source) { "<div>content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple void elements have self-closing slashes" do
      let(:source) do
        <<~HTML
          <br/>
          <hr/>
          <img src="photo.jpg" />
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:message)).to contain_exactly(
          "Void element 'br' should not have a self-closing slash",
          "Void element 'hr' should not have a self-closing slash",
          "Void element 'img' should not have a self-closing slash"
        )
      end
    end

    context "when void element is nested inside non-void element" do
      let(:source) do
        <<~HTML
          <div>
            <img src="photo.jpg" />
          </div>
        HTML
      end

      it "reports an offense for the nested void element" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Void element 'img' should not have a self-closing slash")
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
