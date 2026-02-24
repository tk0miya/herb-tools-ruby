# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::Rewriters::Base do
  describe ".rewriter_name" do
    subject { described_class.rewriter_name }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end

  describe ".description" do
    subject { described_class.description }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end

  describe ".phase" do
    subject { described_class.phase }

    it "returns :post by default" do
      expect(subject).to eq(:post)
    end
  end

  describe "#initialize" do
    context "with options" do
      subject { described_class.new(options: { foo: "bar" }) }

      it "stores options" do
        expect(subject.options).to eq({ foo: "bar" })
      end
    end

    context "without options" do
      subject { described_class.new }

      it "defaults options to empty hash" do
        expect(subject.options).to eq({})
      end
    end
  end

  describe "#rewrite" do
    subject { described_class.new.rewrite(ast, context) }

    let(:ast) { Herb.parse("<div></div>", track_whitespace: true).value }
    let(:context) { build(:context) }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
