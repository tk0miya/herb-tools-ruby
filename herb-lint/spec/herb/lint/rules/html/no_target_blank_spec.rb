# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoTargetBlank do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/no-target-blank'" do
      expect(described_class.rule_name).to eq("html/no-target-blank")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq('Disallow target="_blank" without rel="noopener" or rel="noreferrer"')
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when target=\"_blank\" is used without rel attribute" do
      let(:template) { '<a href="https://example.com" target="_blank">Link</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
        expect(subject.first.message).to eq(
          'Links with target="_blank" should include rel="noopener" or rel="noreferrer"'
        )
        expect(subject.first.severity).to eq("warning")
      end
    end

    context 'when target="_blank" is used with rel="noopener"' do
      let(:template) { '<a href="https://example.com" target="_blank" rel="noopener">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context 'when target="_blank" is used with rel="noreferrer"' do
      let(:template) { '<a href="https://example.com" target="_blank" rel="noreferrer">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context 'when target="_blank" is used with rel="noopener noreferrer"' do
      let(:template) { '<a href="https://example.com" target="_blank" rel="noopener noreferrer">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there is no target attribute" do
      let(:template) { '<a href="https://example.com">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context 'when target is not "_blank"' do
      let(:template) { '<a href="https://example.com" target="_self">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context 'when target="_blank" has rel with unrelated values' do
      let(:template) { '<a href="https://example.com" target="_blank" rel="stylesheet">Link</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
      end
    end

    context 'when rel includes "noopener" among other values' do
      let(:template) { '<a href="https://example.com" target="_blank" rel="noopener external">Link</a>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when target attribute has uppercase _BLANK" do
      let(:template) { '<a href="https://example.com" target="_BLANK">Link</a>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
      end
    end

    context "when TARGET attribute is uppercase" do
      let(:template) { '<a href="https://example.com" TARGET="_blank">Link</a>' }

      it "reports an offense (case-insensitive attribute name)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
      end
    end

    context "when non-anchor element has target=\"_blank\"" do
      let(:template) { '<form target="_blank" action="/submit"></form>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
      end
    end

    context "when multiple elements have target=\"_blank\" without rel" do
      let(:template) do
        <<~HTML
          <a href="https://example.com" target="_blank">Link 1</a>
          <a href="https://other.com" target="_blank">Link 2</a>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "when some elements have safe rel and some do not" do
      let(:template) do
        <<~HTML
          <a href="https://example.com" target="_blank" rel="noopener">Safe</a>
          <a href="https://other.com" target="_blank">Unsafe</a>
        HTML
      end

      it "reports an offense only for the unsafe element" do
        expect(subject.size).to eq(1)
      end
    end

    context "with nested elements" do
      let(:template) do
        <<~HTML
          <div>
            <a href="https://example.com" target="_blank">Link</a>
          </div>
        HTML
      end

      it "reports an offense for the nested element" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-target-blank")
      end
    end

    context "when rel has noopener in mixed case" do
      let(:template) { '<a href="https://example.com" target="_blank" rel="NoOpener">Link</a>' }

      it "does not report an offense (case-insensitive rel check)" do
        expect(subject).to be_empty
      end
    end
  end
end
