# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::HtmlNoAriaHiddenOnFocusable do
  describe ".rule_name" do
    it "returns 'html-no-aria-hidden-on-focusable'" do
      expect(described_class.rule_name).to eq("html-no-aria-hidden-on-focusable")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq('Disallow aria-hidden="true" on focusable elements')
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
    let(:context) { instance_double(Herb::Lint::Context) }

    context "when aria-hidden=\"true\" is on a button" do
      let(:source) { '<button aria-hidden="true">Click</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-aria-hidden-on-focusable")
        expect(subject.first.message).to include("focusable should not have `aria-hidden=\"true\"`")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when aria-hidden=\"true\" is on an anchor with href" do
      let(:source) { '<a href="/page" aria-hidden="true">Link</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-aria-hidden-on-focusable")
      end
    end

    context "when aria-hidden=\"true\" is on a non-focusable div" do
      let(:source) { '<div aria-hidden="true">Decorative</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when button does not have aria-hidden" do
      let(:source) { "<button>Click</button>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when aria-hidden is \"false\" on a button" do
      let(:source) { '<button aria-hidden="false">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when anchor without href has aria-hidden=\"true\"" do
      let(:source) { '<a aria-hidden="true">Not a link</a>' }

      it "does not report an offense (anchor without href is not focusable)" do
        expect(subject).to be_empty
      end
    end

    context "when anchor without href has tabindex=\"0\" and aria-hidden=\"true\"" do
      let(:source) { '<a tabindex="0" aria-hidden="true">Focusable link</a>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when button has tabindex=\"-1\" and aria-hidden=\"true\"" do
      let(:source) { '<button tabindex="-1" aria-hidden="true">Not focusable</button>' }

      it "does not report an offense (negative tabindex removes focusability)" do
        expect(subject).to be_empty
      end
    end

    context "when div has tabindex=\"0\" and aria-hidden=\"true\"" do
      let(:source) { '<div tabindex="0" aria-hidden="true">Focusable div</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
      end
    end

    context "when div has tabindex=\"-1\" and aria-hidden=\"true\"" do
      let(:source) { '<div tabindex="-1" aria-hidden="true">Not focusable</div>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when ARIA-HIDDEN attribute is uppercase" do
      let(:source) { '<button ARIA-HIDDEN="true">Click</button>' }

      it "reports an offense (case insensitive)" do
        expect(subject.size).to eq(1)
      end
    end

    context "when aria-hidden value is \"TRUE\" (uppercase)" do
      let(:source) { '<button aria-hidden="TRUE">Click</button>' }

      it "reports an offense (case insensitive value)" do
        expect(subject.size).to eq(1)
      end
    end

    context "with multiple focusable elements having aria-hidden=\"true\"" do
      let(:source) do
        <<~HTML
          <button aria-hidden="true">Button</button>
          <a href="/page" aria-hidden="true">Link</a>
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("html-no-aria-hidden-on-focusable"))
      end
    end

    context "with mixed focusable and non-focusable elements" do
      let(:source) do
        <<~HTML
          <div aria-hidden="true">Decorative</div>
          <button aria-hidden="true">Click</button>
          <span aria-hidden="true">Hidden</span>
        HTML
      end

      it "reports offense only for the focusable element" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(2)
      end
    end
  end
end
