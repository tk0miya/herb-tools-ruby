# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::Rewriters::Base do
  describe ".rewriter_name" do
    it "raises NotImplementedError" do
      expect { described_class.rewriter_name }.to raise_error(NotImplementedError)
    end
  end

  describe ".description" do
    it "raises NotImplementedError" do
      expect { described_class.description }.to raise_error(NotImplementedError)
    end
  end

  describe ".phase" do
    it "returns :post by default" do
      expect(described_class.phase).to eq(:post)
    end
  end

  describe "#initialize" do
    context "with options" do
      it "stores the options" do
        rewriter = described_class.new(options: { foo: "bar" })
        expect(rewriter.options).to eq({ foo: "bar" })
      end
    end

    context "without options" do
      it "defaults options to empty hash" do
        rewriter = described_class.new
        expect(rewriter.options).to eq({})
      end
    end
  end

  describe "#rewrite" do
    subject { described_class.new.rewrite(ast, formatting_context) }

    let(:ast) { instance_double(Herb::AST::DocumentNode) }
    let(:formatting_context) { instance_double(Herb::Format::Context) }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
