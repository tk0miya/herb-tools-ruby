# frozen_string_literal: true

RSpec.describe Herb::Lint::ConsoleUtils do
  let(:test_class) { Class.new { include Herb::Lint::ConsoleUtils } }
  let(:instance) { test_class.new }

  describe "#colorize" do
    subject { instance.colorize(text, color:, bold:, dim:, tty:) }

    let(:text) { "text" }
    let(:color) { nil }
    let(:bold) { false }
    let(:dim) { false }
    let(:tty) { false }

    context "with TTY output" do
      let(:tty) { true }

      context "when applying red color" do
        let(:color) { :red }

        it { is_expected.to eq("\e[31mtext\e[0m") }
      end

      context "when applying green color" do
        let(:color) { :green }

        it { is_expected.to eq("\e[32mtext\e[0m") }
      end

      context "when applying yellow color" do
        let(:color) { :yellow }

        it { is_expected.to eq("\e[33mtext\e[0m") }
      end

      context "when applying cyan color" do
        let(:color) { :cyan }

        it { is_expected.to eq("\e[36mtext\e[0m") }
      end

      context "when applying gray color" do
        let(:color) { :gray }

        it { is_expected.to eq("\e[90mtext\e[0m") }
      end

      context "when applying bold style" do
        let(:bold) { true }

        it { is_expected.to eq("\e[1mtext\e[0m") }
      end

      context "when applying dim style" do
        let(:dim) { true }

        it { is_expected.to eq("\e[2mtext\e[0m") }
      end

      context "when applying color and bold together" do
        let(:color) { :red }
        let(:bold) { true }

        it { is_expected.to eq("\e[1;31mtext\e[0m") }
      end

      context "when applying color, bold, and dim together" do
        let(:color) { :cyan }
        let(:bold) { true }
        let(:dim) { true }

        it { is_expected.to eq("\e[1;2;36mtext\e[0m") }
      end

      context "when no options are provided" do
        it { is_expected.to eq("text") }
      end
    end

    context "with non-TTY output" do
      let(:tty) { false }

      context "when color and bold are specified" do
        let(:color) { :red }
        let(:bold) { true }

        it { is_expected.to eq("text") }
      end

      context "when bold and dim are specified" do
        let(:bold) { true }
        let(:dim) { true }

        it { is_expected.to eq("text") }
      end
    end
  end
end
