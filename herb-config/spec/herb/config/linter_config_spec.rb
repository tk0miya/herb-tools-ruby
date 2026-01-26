# frozen_string_literal: true

RSpec.describe Herb::Config::LinterConfig do
  describe "#enabled?" do
    context "when enabled is not specified" do
      it "returns true by default" do
        config = { "linter" => {} }
        linter_config = described_class.new(config)

        expect(linter_config.enabled?).to be(true)
      end
    end

    context "when enabled is explicitly set to true" do
      it "returns true" do
        config = { "linter" => { "enabled" => true } }
        linter_config = described_class.new(config)

        expect(linter_config.enabled?).to be(true)
      end
    end

    context "when enabled is explicitly set to false" do
      it "returns false" do
        config = { "linter" => { "enabled" => false } }
        linter_config = described_class.new(config)

        expect(linter_config.enabled?).to be(false)
      end
    end
  end

  describe "#include_patterns" do
    context "when include patterns are specified" do
      it "returns the configured patterns" do
        config = { "linter" => { "include" => ["app/**/*.erb", "lib/**/*.erb"] } }
        linter_config = described_class.new(config)

        expect(linter_config.include_patterns).to eq(["app/**/*.erb", "lib/**/*.erb"])
      end
    end

    context "when include patterns are not specified" do
      it "returns default patterns" do
        config = { "linter" => {} }
        linter_config = described_class.new(config)

        expect(linter_config.include_patterns).to eq(["**/*.html.erb"])
      end
    end
  end

  describe "#exclude_patterns" do
    context "when exclude patterns are specified" do
      it "returns the configured patterns" do
        config = { "linter" => { "exclude" => ["vendor/**", "node_modules/**"] } }
        linter_config = described_class.new(config)

        expect(linter_config.exclude_patterns).to eq(["vendor/**", "node_modules/**"])
      end
    end

    context "when exclude patterns are not specified" do
      it "returns default patterns" do
        config = { "linter" => {} }
        linter_config = described_class.new(config)

        expect(linter_config.exclude_patterns).to eq([])
      end
    end
  end

  describe "#rules" do
    context "when rules are configured" do
      it "returns the rules hash" do
        config = {
          "linter" => {
            "rules" => {
              "alt-text" => "error",
              "attribute-quotes" => "warn"
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rules).to eq({
          "alt-text" => "error",
          "attribute-quotes" => "warn"
        })
      end
    end

    context "when rules are not configured" do
      it "returns empty hash" do
        config = { "linter" => {} }
        linter_config = described_class.new(config)

        expect(linter_config.rules).to eq({})
      end
    end
  end

  describe "#rule_enabled?" do
    context "when rule is not configured" do
      it "returns true (enabled by default)" do
        config = { "linter" => { "rules" => {} } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_enabled?("alt-text")).to be(true)
      end
    end

    context "when rule is set to error" do
      it "returns true" do
        config = { "linter" => { "rules" => { "alt-text" => "error" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_enabled?("alt-text")).to be(true)
      end
    end

    context "when rule is set to warn" do
      it "returns true" do
        config = { "linter" => { "rules" => { "alt-text" => "warn" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_enabled?("alt-text")).to be(true)
      end
    end

    context "when rule is set to off" do
      it "returns false" do
        config = { "linter" => { "rules" => { "alt-text" => "off" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_enabled?("alt-text")).to be(false)
      end
    end

    context "when rule has hash configuration with off severity" do
      it "returns false" do
        config = {
          "linter" => {
            "rules" => {
              "alt-text" => { "severity" => "off" }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_enabled?("alt-text")).to be(false)
      end
    end
  end

  describe "#rule_severity" do
    context "when rule is not configured" do
      it "returns the default severity" do
        config = { "linter" => { "rules" => {} } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:warn)
        expect(linter_config.rule_severity("alt-text", default: :error)).to eq(:error)
      end
    end

    context "when rule is configured as string" do
      it "returns the severity as symbol" do
        config = { "linter" => { "rules" => { "alt-text" => "error" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:error)
      end
    end

    context "when rule is configured as symbol" do
      it "returns the severity as symbol" do
        config = { "linter" => { "rules" => { "alt-text" => :warn } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:warn)
      end
    end

    context "when rule has hash configuration with string severity key" do
      it "returns the severity from the hash" do
        config = {
          "linter" => {
            "rules" => {
              "alt-text" => { "severity" => "error" }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:error)
      end
    end

    context "when rule has hash configuration with symbol severity key" do
      it "returns the severity from the hash" do
        config = {
          "linter" => {
            "rules" => {
              "alt-text" => { severity: "info" }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:info)
      end
    end

    context "when severity alias is used" do
      it "normalizes warning to warn" do
        config = { "linter" => { "rules" => { "alt-text" => "warning" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:warn)
      end
    end

    context "when invalid severity is used" do
      it "falls back to warn" do
        config = { "linter" => { "rules" => { "alt-text" => "invalid" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_severity("alt-text")).to eq(:warn)
      end
    end

    context "with all valid severity levels" do
      it "correctly parses each severity level" do
        %w[error warn info hint off].each do |severity|
          config = { "linter" => { "rules" => { "alt-text" => severity } } }
          linter_config = described_class.new(config)

          expect(linter_config.rule_severity("alt-text")).to eq(severity.to_sym)
        end
      end
    end
  end

  describe "#rule_options" do
    context "when rule is not configured" do
      it "returns empty hash" do
        config = { "linter" => { "rules" => {} } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_options("alt-text")).to eq({})
      end
    end

    context "when rule is configured as string" do
      it "returns empty hash" do
        config = { "linter" => { "rules" => { "alt-text" => "error" } } }
        linter_config = described_class.new(config)

        expect(linter_config.rule_options("alt-text")).to eq({})
      end
    end

    context "when rule has options with string key" do
      it "returns the options hash" do
        config = {
          "linter" => {
            "rules" => {
              "attribute-quotes" => {
                "severity" => "error",
                "options" => { "style" => "double" }
              }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_options("attribute-quotes")).to eq({ "style" => "double" })
      end
    end

    context "when rule has options with symbol key" do
      it "returns the options hash" do
        config = {
          "linter" => {
            "rules" => {
              "attribute-quotes" => {
                severity: "error",
                options: { style: "double" }
              }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_options("attribute-quotes")).to eq({ style: "double" })
      end
    end

    context "when rule hash has no options" do
      it "returns empty hash" do
        config = {
          "linter" => {
            "rules" => {
              "alt-text" => { "severity" => "error" }
            }
          }
        }
        linter_config = described_class.new(config)

        expect(linter_config.rule_options("alt-text")).to eq({})
      end
    end
  end

  describe "rule name normalization" do
    it "handles underscores in rule names" do
      config = { "linter" => { "rules" => { "alt-text" => "error" } } }
      linter_config = described_class.new(config)

      expect(linter_config.rule_severity("alt_text")).to eq(:error)
    end

    it "handles symbol rule names" do
      config = { "linter" => { "rules" => { "alt-text" => "error" } } }
      linter_config = described_class.new(config)

      expect(linter_config.rule_severity(:"alt-text")).to eq(:error)
    end
  end

  describe "with missing linter section" do
    it "uses defaults for all methods" do
      config = {}
      linter_config = described_class.new(config)

      expect(linter_config.enabled?).to be(true)
      expect(linter_config.include_patterns).to eq(["**/*.html.erb"])
      expect(linter_config.exclude_patterns).to eq([])
      expect(linter_config.rules).to eq({})
      expect(linter_config.rule_enabled?("alt-text")).to be(true)
      expect(linter_config.rule_severity("alt-text")).to eq(:warn)
      expect(linter_config.rule_options("alt-text")).to eq({})
    end
  end
end
