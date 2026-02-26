# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::RewriterRegistry do
  let(:registry) { described_class.new }

  describe "#get" do
    subject { registry.get(name) }

    context "when the rewriter is not registered" do
      let(:name) { "unknown" }

      it { is_expected.to be_nil }
    end

    context "when load_builtin_rewriters has been called" do
      let(:name) { "tailwind-class-sorter" }

      before { registry.load_builtin_rewriters }

      it "returns nil (built-ins moved to herb-rewriter gem)" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#load_builtin_rewriters" do
    subject { registry.load_builtin_rewriters }

    it "does not raise an error" do
      expect { subject }.not_to raise_error
    end
  end

  describe "#load_custom_rewriters" do
    subject { registry.load_custom_rewriters(names) }

    context "with an empty list" do
      let(:names) { [] }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "does not register any rewriters" do
        subject
        expect(registry.get("custom-test-rewriter")).to be_nil
      end
    end

    context "with a require name that does not exist" do
      let(:names) { ["nonexistent_gem_that_does_not_exist"] }

      it "raises LoadError" do
        expect { subject }.to raise_error(LoadError)
      end
    end
  end
end
