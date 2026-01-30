# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoPositiveTabIndex do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/no-positive-tab-index'" do
      expect(described_class.rule_name).to eq("html/no-positive-tab-index")
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
    context "when tabindex is 0" do
      let(:template) { '<button tabindex="0">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tabindex is -1" do
      let(:template) { '<button tabindex="-1">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tabindex is a positive integer" do
      let(:template) { '<button tabindex="1">Click</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-positive-tab-index")
        expect(subject.first.message).to eq("Avoid positive tabindex value '1' (disrupts natural tab order)")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when there is no tabindex attribute" do
      let(:template) { "<button>Click</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are multiple elements with positive tabindex" do
      let(:template) do
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
      let(:template) do
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
      let(:template) { '<button tabindex="abc">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with other attributes present" do
      let(:template) { '<button class="btn" tabindex="3" id="submit">Click</button>' }

      it "reports an offense for the positive tabindex" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid positive tabindex value '3' (disrupts natural tab order)")
      end
    end

    context "with tabindex attribute in different case" do
      let(:template) { '<button TABINDEX="1">Click</button>' }

      it "reports an offense (case-insensitive check)" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-positive-tab-index")
      end
    end

    context "with nested elements" do
      let(:template) do
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
