# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::ImgRequireAlt do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/img-require-alt'" do
      expect(described_class.rule_name).to eq("html/img-require-alt")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Require alt attribute on img tags")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    context "when img tag has alt attribute" do
      let(:template) { '<img src="image.png" alt="Description">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when img tag has empty alt attribute" do
      let(:template) { '<img src="decorative.png" alt="">' }

      it "does not report an offense (empty alt is valid for decorative images)" do
        expect(subject).to be_empty
      end
    end

    context "when img tag is missing alt attribute" do
      let(:template) { '<img src="image.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/img-require-alt")
        expect(subject.first.message).to eq("Missing alt attribute on img tag")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when multiple img tags are missing alt attribute" do
      let(:template) { '<img src="a.png"><img src="b.png">' }

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html/img-require-alt"))
      end
    end

    context "when img tag has uppercase ALT attribute" do
      let(:template) { '<img src="image.png" ALT="Description">' }

      it "does not report an offense (case insensitive)" do
        expect(subject).to be_empty
      end
    end

    context "when IMG tag is uppercase" do
      let(:template) { '<IMG src="image.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "with non-img elements" do
      let(:template) { '<div class="container"><p>Hello</p></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end

    context "with mixed img tags on multiple lines" do
      let(:template) do
        <<~HTML
          <img src="a.png" alt="A">
          <img src="b.png">
          <img src="c.png" alt="C">
        HTML
      end

      it "reports offense only for img without alt with correct line number" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
