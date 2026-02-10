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
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when tabindex is 0" do
      let(:source) { '<button tabindex="0">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tabindex is -1" do
      let(:source) { '<button tabindex="-1">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tabindex is a positive integer" do
      let(:source) { '<button tabindex="1">Click</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-positive-tab-index")
        expect(subject.first.message).to eq("Avoid positive tabindex value '1' (disrupts natural tab order)")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when there is no tabindex attribute" do
      let(:source) { "<button>Click</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

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
        expect(subject.first.message).to eq("Avoid positive tabindex value '1' (disrupts natural tab order)")
      end
    end

    context "with non-numeric tabindex value" do
      let(:source) { '<button tabindex="abc">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with other attributes present" do
      let(:source) { '<button class="btn" tabindex="3" id="submit">Click</button>' }

      it "reports an offense for the positive tabindex" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid positive tabindex value '3' (disrupts natural tab order)")
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
