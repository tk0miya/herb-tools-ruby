# frozen_string_literal: true

RSpec.describe Herb::Config::Defaults do
  describe ".config" do
    subject(:config) { described_class.config }

    it "returns a hash with linter section containing default values" do
      expect(config).to have_key("linter")
      expect(config["linter"]["include"]).to eq(["**/*.html.erb"])
      expect(config["linter"]["exclude"]).to eq([])
      expect(config["linter"]["custom_rules"]).to eq([])
      expect(config["linter"]["rules"]).to eq({})
    end

    it "returns a new mutable hash each time" do
      config1 = described_class.config
      config2 = described_class.config
      expect(config1).not_to be(config2)

      config1["linter"]["rules"]["test"] = "error"
      expect(config2["linter"]["rules"]).to eq({})
    end
  end

  describe ".merge" do
    context "when user_config is empty" do
      it "returns defaults" do
        result = described_class.merge({})
        expect(result).to eq(described_class.config)
      end
    end

    context "when user_config has custom top-level keys" do
      let(:user_config) { { "custom" => "value" } }

      it "adds custom keys while preserving defaults" do
        result = described_class.merge(user_config)
        expect(result["custom"]).to eq("value")
        expect(result["linter"]).to be_a(Hash)
      end
    end

    context "when user_config overrides linter settings" do
      it "deep merges nested hashes preserving unspecified defaults" do
        user_config = {
          "linter" => {
            "rules" => { "alt-text" => "error" }
          }
        }
        result = described_class.merge(user_config)

        expect(result["linter"]["include"]).to eq(["**/*.html.erb"])
        expect(result["linter"]["exclude"]).to eq([])
        expect(result["linter"]["rules"]).to eq({ "alt-text" => "error" })
      end

      it "replaces arrays entirely rather than merging elements" do
        user_config = {
          "linter" => {
            "include" => ["custom/*.erb"],
            "exclude" => ["vendor/**"]
          }
        }
        result = described_class.merge(user_config)

        expect(result["linter"]["include"]).to eq(["custom/*.erb"])
        expect(result["linter"]["exclude"]).to eq(["vendor/**"])
      end

      it "handles deeply nested hashes" do
        user_config = {
          "linter" => {
            "rules" => {
              "alt-text" => { "severity" => "error", "options" => { "strict" => true } }
            }
          }
        }
        result = described_class.merge(user_config)

        expect(result["linter"]["rules"]["alt-text"]["severity"]).to eq("error")
        expect(result["linter"]["rules"]["alt-text"]["options"]["strict"]).to be(true)
      end
    end
  end
end
