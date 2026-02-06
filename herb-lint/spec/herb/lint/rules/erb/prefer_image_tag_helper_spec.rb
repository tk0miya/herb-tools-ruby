# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::PreferImageTagHelper do
  describe ".rule_name" do
    it "returns 'erb-prefer-image-tag-helper'" do
      expect(described_class.rule_name).to eq("erb-prefer-image-tag-helper")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Prefer Rails image_tag helper over raw <img> tags")
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

    context "when using image_tag helper" do
      let(:source) { "<%= image_tag 'logo.png' %>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using raw img tag" do
      let(:source) { '<img src="logo.png" alt="Company Logo">' }

      it "reports an offense with correct details" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
        expect(subject.first.message).to eq("Prefer using <%= image_tag %> helper instead of <img> tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when using uppercase IMG tag" do
      let(:source) { '<IMG src="logo.png">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when multiple img tags exist" do
      let(:source) do
        <<~HTML
          <img src="logo.png">
          <img src="banner.jpg" alt="Banner">
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("erb-prefer-image-tag-helper"))
        expect(subject.map(&:line)).to contain_exactly(1, 2)
      end
    end

    context "when mixing img tags and image_tag helpers" do
      let(:source) do
        <<~ERB
          <%= image_tag 'logo.png' %>
          <img src="banner.jpg">
          <%= image_tag 'icon.png' %>
        ERB
      end

      it "reports offense only for raw img tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end

    context "with non-img elements" do
      let(:source) { '<div><p>Hello</p><a href="#">Link</a></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
