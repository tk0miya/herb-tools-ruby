# frozen_string_literal: true

require "tempfile"

RSpec.describe Herb::Highlighter::Themes do
  before do
    # Reset to empty state before each test to prevent cross-test contamination
    described_class.instance_variable_set(:@themes, {})
  end

  describe ".names" do
    subject { described_class.names }

    context "with registered themes" do
      before do
        described_class.register("theme-a", {})
        described_class.register("theme-b", {})
      end

      it "returns all built-in theme names" do
        expect(subject).to contain_exactly("theme-a", "theme-b")
      end
    end

    context "without registered themes" do
      it "returns empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe ".resolve" do
    subject { described_class.resolve(theme) }

    context "with a defined built-in theme name" do
      let(:theme) { "testtheme" }

      before { described_class.register("testtheme", { "TOKEN_ERB_START" => "cyan" }) }

      it "returns the theme hash" do
        expect(subject).to eq({ "TOKEN_ERB_START" => "cyan" })
      end
    end

    context "with an undefined name" do
      let(:theme) { "unknown-theme" }

      it "raises RuntimeError (treats as file path)" do
        expect { subject }.to raise_error(RuntimeError, /Failed to load custom theme from/)
      end
    end

    context "with a file path to a valid JSON theme" do
      let(:tempfile) { Tempfile.new(["custom", ".json"]) }
      let(:theme) { tempfile.path }

      before do
        tempfile.write(JSON.generate({ "TOKEN_HTML_TAG_END" => "#56b6c2" }))
        tempfile.flush
      end

      after { tempfile.close! }

      it "loads and returns the custom theme" do
        expect(subject).to eq({ "TOKEN_HTML_TAG_END" => "#56b6c2" })
      end
    end

    context "with a file path to a missing file" do
      let(:theme) { "/nonexistent/path/theme.json" }

      it "raises RuntimeError with descriptive message" do
        expect { subject }.to raise_error(RuntimeError, /Failed to load custom theme from/)
      end
    end

    context "with a file path to invalid JSON" do
      let(:tempfile) { Tempfile.new(["bad", ".json"]) }
      let(:theme) { tempfile.path }

      before do
        tempfile.write("not valid json {{{")
        tempfile.flush
      end

      after { tempfile.close! }

      it "raises RuntimeError with descriptive message" do
        expect { subject }.to raise_error(RuntimeError, /Failed to load custom theme from/)
      end
    end

    context "with missing required keys (when onedark is defined as reference)" do
      let(:tempfile) { Tempfile.new(["partial", ".json"]) }
      let(:theme) { tempfile.path }

      before do
        described_class.register("onedark", { "TOKEN_A" => "#000", "TOKEN_B" => "#111" })
        tempfile.write(JSON.generate({ "TOKEN_A" => "#fff" }))
        tempfile.flush
      end

      after { tempfile.close! }

      it "raises RuntimeError listing missing keys" do
        expect { subject }.to raise_error(RuntimeError, /TOKEN_B/)
      end
    end

    context "when no built-in themes are defined" do
      let(:tempfile) { Tempfile.new(["any", ".json"]) }
      let(:theme) { tempfile.path }

      before do
        tempfile.write(JSON.generate({ "SOME_KEY" => "#abc" }))
        tempfile.flush
      end

      after { tempfile.close! }

      it "skips key validation for custom themes" do
        expect(subject).to eq({ "SOME_KEY" => "#abc" })
      end
    end
  end

  describe ".register" do
    subject { described_class.register(name, mapping) }

    let(:name) { "new-theme" }
    let(:mapping) { { "TOKEN_ERB_END" => "#ffffff" } }

    it "adds the theme to the registry" do
      subject
      expect(described_class.resolve("new-theme")).to eq({ "TOKEN_ERB_END" => "#ffffff" })
      expect(described_class.names).to include("new-theme")
    end
  end
end
