# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::ContentUnit do
  describe "#initialize" do
    context "with only required arguments" do
      subject { described_class.new(content: "hello") }

      it "sets content and uses default values" do
        expect(subject.content).to eq("hello")
        expect(subject.type).to eq(:text)
        expect(subject.is_atomic).to be(false)
        expect(subject.breaks_flow).to be(false)
        expect(subject.is_herb_disable).to be(false)
      end
    end

    context "with all arguments specified" do
      subject do
        described_class.new(
          content: "<%= user.name %>",
          type: :erb,
          is_atomic: true,
          breaks_flow: false,
          is_herb_disable: false
        )
      end

      it "stores all provided values" do
        expect(subject.content).to eq("<%= user.name %>")
        expect(subject.type).to eq(:erb)
        expect(subject.is_atomic).to be(true)
        expect(subject.breaks_flow).to be(false)
        expect(subject.is_herb_disable).to be(false)
      end
    end

    context "with breaks_flow: true" do
      subject { described_class.new(content: "", type: :block, is_atomic: true, breaks_flow: true) }

      it "stores breaks_flow as true" do
        expect(subject.breaks_flow).to be(true)
        expect(subject.type).to eq(:block)
        expect(subject.is_atomic).to be(true)
      end
    end

    context "with is_herb_disable: true" do
      subject { described_class.new(content: "<%# herb:disable %>", type: :erb, is_atomic: true, is_herb_disable: true) }

      it "stores is_herb_disable as true" do
        expect(subject.is_herb_disable).to be(true)
      end
    end
  end
end

RSpec.describe Herb::Format::ContentUnitWithNode do
  describe "#initialize" do
    let(:unit) { Herb::Format::ContentUnit.new(content: "hello") }

    context "with unit and nil node" do
      subject { described_class.new(unit: unit, node: nil) }

      it "stores unit and nil node" do
        expect(subject.unit).to eq(unit)
        expect(subject.node).to be_nil
      end
    end

    context "with unit and a node" do
      let(:source) { "<p>Hello</p>" }
      let(:node) { Herb.parse(source, track_whitespace: true).value.children.first }
      subject { described_class.new(unit: unit, node: node) }

      it "stores unit and node" do
        expect(subject.unit).to eq(unit)
        expect(subject.node).to eq(node)
      end
    end
  end
end
