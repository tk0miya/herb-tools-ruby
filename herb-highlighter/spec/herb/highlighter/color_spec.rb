# frozen_string_literal: true

RSpec.describe Herb::Highlighter::Color do
  describe ".ansi_code" do
    subject { described_class.ansi_code(color) }

    context "with hex color" do
      let(:color) { "#FF0000" }

      it "returns 24-bit true-color foreground escape sequence" do
        expect(subject).to eq("\e[38;2;255;0;0m")
      end
    end

    context "with lowercase hex color" do
      let(:color) { "#ff8800" }

      it "returns correct 24-bit escape sequence" do
        expect(subject).to eq("\e[38;2;255;136;0m")
      end
    end

    context "with named color" do
      let(:color) { "red" }

      it "returns the ANSI code" do
        expect(subject).to eq("\e[31m")
      end
    end

    context "with camelCase named color" do
      let(:color) { "brightRed" }

      it "returns the correct ANSI code" do
        expect(subject).to eq("\e[91m")
      end
    end

    context "with unknown name" do
      let(:color) { "unknown" }

      it { is_expected.to be_nil }
    end
  end

  describe ".background_ansi_code" do
    subject { described_class.background_ansi_code(color) }

    context "with hex color" do
      let(:color) { "#0000FF" }

      it "returns 24-bit true-color background escape sequence" do
        expect(subject).to eq("\e[48;2;0;0;255m")
      end
    end

    context "with named color" do
      let(:color) { "bgRed" }

      it "returns the ANSI code" do
        expect(subject).to eq("\e[41m")
      end
    end

    context "with unknown name" do
      let(:color) { "unknown" }

      it { is_expected.to be_nil }
    end
  end

  describe ".colorize" do
    subject { described_class.colorize(text, color, **opts) }

    let(:text) { "Hello" }
    let(:opts) { {} }

    context "with hex color" do
      let(:color) { "#FF0000" }

      it { is_expected.to eq("\e[38;2;255;0;0mHello\e[0m") }
    end

    context "with named color" do
      let(:color) { "red" }

      it { is_expected.to eq("\e[31mHello\e[0m") }
    end

    context "with unknown color" do
      let(:color) { "unknown" }

      it { is_expected.to eq(text) }
    end

    context "with NO_COLOR set" do
      let(:color) { "red" }

      around do |example|
        ENV["NO_COLOR"] = "1"
        example.run
      ensure
        ENV.delete("NO_COLOR")
      end

      it { is_expected.to eq(text) }
    end

    context "with background_color as hex" do
      let(:color) { "red" }
      let(:opts) { { background_color: "#0000FF" } }

      it { is_expected.to eq("\e[48;2;0;0;255m\e[31mHello\e[0m") }
    end

    context "with background_color as named color" do
      let(:color) { "white" }
      let(:opts) { { background_color: "bgBlue" } }

      it { is_expected.to eq("\e[44m\e[37mHello\e[0m") }
    end

    context "with nil background_color" do
      let(:color) { "green" }
      let(:opts) { { background_color: nil } }

      it { is_expected.to eq("\e[32mHello\e[0m") }
    end
  end

  describe ".severity_color" do
    subject { described_class.severity_color(severity) }

    context 'with "error"' do
      let(:severity) { "error" }

      it { is_expected.to eq("brightRed") }
    end

    context 'with "warning"' do
      let(:severity) { "warning" }

      it { is_expected.to eq("brightYellow") }
    end

    context 'with "info"' do
      let(:severity) { "info" }

      it { is_expected.to eq("cyan") }
    end

    context 'with "hint"' do
      let(:severity) { "hint" }

      it { is_expected.to eq("gray") }
    end

    context "with unknown severity" do
      let(:severity) { "unknown" }

      it { is_expected.to eq("brightYellow") }
    end
  end
end
