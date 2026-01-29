# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoInlineEventHandlers do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template) }
  let(:context) { instance_double(Herb::Lint::Context) }

  describe ".rule_name" do
    it "returns 'html/no-inline-event-handlers'" do
      expect(described_class.rule_name).to eq("html/no-inline-event-handlers")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow inline event handlers")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when element has no inline event handlers" do
      let(:template) { '<button type="button">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element uses data attributes instead of event handlers" do
      let(:template) { '<button data-action="click">Click</button>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when element has onclick handler" do
      let(:template) { '<button onclick="handleClick()">Click</button>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html/no-inline-event-handlers")
        expect(subject.first.message).to eq("Avoid inline event handler 'onclick'")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when element has onmouseover handler" do
      let(:template) { '<div onmouseover="highlight()">Hover me</div>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid inline event handler 'onmouseover'")
      end
    end

    context "when element has onsubmit handler" do
      let(:template) { '<form onsubmit="validate()"></form>' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid inline event handler 'onsubmit'")
      end
    end

    context "when element has uppercase event handler" do
      let(:template) { '<button ONCLICK="handleClick()">Click</button>' }

      it "reports an offense with original attribute name" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid inline event handler 'ONCLICK'")
      end
    end

    context "when element has multiple inline event handlers" do
      let(:template) { '<button onclick="handleClick()" onmouseover="highlight()">Click</button>' }

      it "reports an offense for each handler" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "Avoid inline event handler 'onclick'",
          "Avoid inline event handler 'onmouseover'"
        )
      end
    end

    context "when multiple elements have inline event handlers" do
      let(:template) do
        <<~HTML
          <button onclick="handleClick()">Click</button>
          <div onmouseover="highlight()">Hover</div>
        HTML
      end

      it "reports an offense for each element" do
        expect(subject.size).to eq(2)
      end
    end

    context "when nested element has inline event handler" do
      let(:template) do
        <<~HTML
          <div>
            <button onclick="handleClick()">Click</button>
          </div>
        HTML
      end

      it "reports an offense for the nested element" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Avoid inline event handler 'onclick'")
      end
    end

    context "when element has no attributes" do
      let(:template) { "<div>Content</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when various event handlers are used" do
      let(:template) do
        <<~HTML
          <input onchange="update()" onfocus="highlight()" onblur="reset()">
        HTML
      end

      it "reports an offense for each handler" do
        expect(subject.size).to eq(3)
      end
    end
  end
end
