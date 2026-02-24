# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::ContentUnit do
  describe Herb::Format::ContentUnit do
    describe "#initialize" do
      context "with only required content argument" do
        subject { described_class.new(content: "hello world") }

        it "sets content and applies default values" do
          expect(subject.content).to eq("hello world")
          expect(subject.type).to eq(:text)
          expect(subject.is_atomic).to be(false)
          expect(subject.breaks_flow).to be(false)
          expect(subject.is_herb_disable).to be(false)
        end
      end

      context "with all fields specified" do
        subject { described_class.new(content: "", type: :block, is_atomic: true, breaks_flow: true) }

        it "sets all fields" do
          expect(subject.type).to eq(:block)
          expect(subject.is_atomic).to be(true)
          expect(subject.breaks_flow).to be(true)
          expect(subject.is_herb_disable).to be(false)
        end
      end
    end
  end

  describe Herb::Format::ContentUnitWithNode do
    describe "#initialize" do
      context "with a unit and an AST node" do
        subject { described_class.new(unit:, node:) }

        let(:unit) { Herb::Format::ContentUnit.new(content: "<%= x %>", type: :erb, is_atomic: true) }
        let(:node) { Herb.parse("<%= x %>", track_whitespace: true).value.children.first }

        it "stores unit and node" do
          expect(subject.unit).to eq(unit)
          expect(subject.node).not_to be_nil
        end
      end
    end
  end
end
