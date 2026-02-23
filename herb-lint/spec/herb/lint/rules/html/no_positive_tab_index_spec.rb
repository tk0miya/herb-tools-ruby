# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoPositiveTabIndex do
  describe ".rule_name" do
    it "returns 'html-no-positive-tab-index'" do
      expect(described_class.rule_name).to eq("html-no-positive-tab-index")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow positive tabindex values")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "when no tabindex attribute (natural tab order)" do
      let(:source) do
        <<~HTML
          <button>First</button>
          <button>Second</button>
          <button>Third</button>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when non-interactive element with tabindex=\"0\"" do
      let(:source) { '<div tabindex="0" role="button">Custom button</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button with tabindex=\"-1\"" do
      let(:source) { '<button tabindex="-1">Skip this in tab order</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when span with tabindex=\"0\"" do
      let(:source) { '<span tabindex="0" role="button">Focusable span</span>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when button with tabindex=\"3\"" do
      let(:source) { '<button tabindex="3">Third in tab order</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-positive-tab-index")
        expect(subject.first.message).to include("Do not use positive `tabindex` values")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when button with tabindex=\"1\"" do
      let(:source) { '<button tabindex="1">First in tab order</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-positive-tab-index")
      end
    end

    context "when button with tabindex=\"2\"" do
      let(:source) { '<button tabindex="2">Second in tab order</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when input with tabindex=\"5\"" do
      let(:source) { '<input tabindex="5" type="text" autocomplete="off">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when button with tabindex=\"10\"" do
      let(:source) { '<button tabindex="10">Submit</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    # Edge cases not covered by documentation
    context "when there are multiple elements with positive tabindex" do
      let(:source) do
        <<~HTML
          <button tabindex="1">First</button>
          <button tabindex="2">Second</button>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "when only some elements have positive tabindex" do
      let(:source) do
        <<~HTML
          <button tabindex="0">OK</button>
          <button tabindex="1">Bad</button>
          <button tabindex="-1">OK</button>
        HTML
      end

      it "reports an offense only for the positive value" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include("Do not use positive `tabindex` values")
      end
    end

    context "with non-numeric tabindex value" do
      let(:source) { '<button tabindex="abc">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with tabindex attribute in different case" do
      let(:source) { '<button TABINDEX="1">Click</button>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-positive-tab-index")
      end
    end

    context "with nested elements" do
      let(:source) do
        <<~HTML
          <div tabindex="1">
            <button tabindex="2">Click</button>
          </div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end
  end
end
