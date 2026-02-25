# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::CustomRewriterLoader do
  let(:config) { build(:formatter_config) }
  let(:registry) { Herb::Format::RewriterRegistry.new }
  let(:loader) { described_class.new(config, registry) }

  describe "#initialize" do
    subject { described_class.new(config, registry) }

    it "stores config and registry" do
      expect(subject.config).to eq(config)
      expect(subject.registry).to eq(registry)
    end
  end

  describe "#load" do
    subject { loader.load }

    context "when DEFAULT_PATH does not exist" do
      before do
        allow(Dir).to receive(:exist?).with(described_class::DEFAULT_PATH).and_return(false)
      end

      it "does not raise an error and does not register any rewriters" do
        expect { subject }.not_to raise_error
        expect(registry.all).to be_empty
      end
    end

    context "when DEFAULT_PATH exists with no rewriter files" do
      before do
        allow(Dir).to receive(:exist?).with(described_class::DEFAULT_PATH).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(described_class::DEFAULT_PATH, "*.rb")).and_return([])
        registry.load_builtin_rewriters
      end

      it "does not raise an error or register additional rewriters beyond builtins" do
        names_before = registry.rewriter_names.dup
        expect { subject }.not_to raise_error
        expect(registry.rewriter_names).to eq(names_before)
      end
    end

    context "when a rewriter file fails to load" do
      before do
        allow(Dir).to receive(:exist?).with(described_class::DEFAULT_PATH).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(described_class::DEFAULT_PATH, "*.rb")).and_return(
          ["/nonexistent/bad_rewriter.rb"]
        )
      end

      it "warns about the failure without raising an error" do
        expect { loader.load }.to output(/Failed to load rewriter file/).to_stderr
      end
    end

    context "when already-registered rewriters are encountered during auto-registration" do
      before do
        registry.load_builtin_rewriters
        allow(Dir).to receive(:exist?).with(described_class::DEFAULT_PATH).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(described_class::DEFAULT_PATH, "*.rb")).and_return([])
      end

      it "does not raise an error or duplicate-register" do
        subject
        expect(registry.rewriter_names).to eq(["tailwind-class-sorter"])
      end
    end
  end

  describe "DEFAULT_PATH" do
    subject { described_class::DEFAULT_PATH }

    it { is_expected.to eq(".herb/rewriters") }
  end
end
