# frozen_string_literal: true

RSpec.describe Herb::Config::LinterConfig do
  describe "#include_patterns" do
    subject { described_class.new(config).include_patterns }

    context "when linter.include is configured" do
      let(:config) do
        {
          "linter" => {
            "include" => ["app/**/*.erb", "lib/**/*.erb"]
          }
        }
      end

      it "returns the configured patterns" do
        expect(subject).to eq(["app/**/*.erb", "lib/**/*.erb"])
      end
    end

    context "when linter.include is not configured" do
      let(:config) { { "linter" => {} } }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when linter section is missing" do
      let(:config) { {} }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe "#exclude_patterns" do
    subject { described_class.new(config).exclude_patterns }

    context "when linter.exclude is configured" do
      let(:config) do
        {
          "linter" => {
            "exclude" => ["vendor/**", "node_modules/**"]
          }
        }
      end

      it "returns the configured patterns" do
        expect(subject).to eq(["vendor/**", "node_modules/**"])
      end
    end

    context "when linter.exclude is not configured" do
      let(:config) { { "linter" => {} } }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when linter section is missing" do
      let(:config) { {} }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end

  describe "#rules" do
    subject { described_class.new(config).rules }

    context "when linter.rules is configured" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "alt-text" => "error",
              "attribute-quotes" => { "severity" => "warn" }
            }
          }
        }
      end

      it "returns the configured rules" do
        expect(subject).to eq({
                                "alt-text" => "error",
                                "attribute-quotes" => { "severity" => "warn" }
                              })
      end
    end

    context "when linter.rules is not configured" do
      let(:config) { { "linter" => {} } }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when linter section is missing" do
      let(:config) { {} }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end
  end

  describe "#rule_severity" do
    subject { described_class.new(config).rule_severity(rule_name) }

    let(:config) do
      {
        "linter" => {
          "rules" => {
            "error-rule" => { "severity" => "error" },
            "warning-rule" => { "severity" => "warning" },
            "info-rule" => { "severity" => "info" },
            "hint-rule" => { "severity" => "hint" },
            "hash-rule" => { "severity" => "error", "options" => { "style" => "double" } }
          }
        }
      }
    end

    context "when rule has hash configuration with severity" do
      let(:rule_name) { "hash-rule" }

      it "returns the severity from the hash" do
        expect(subject).to eq("error")
      end
    end

    context "when rule has 'error' severity" do
      let(:rule_name) { "error-rule" }

      it "returns 'error'" do
        expect(subject).to eq("error")
      end
    end

    context "when rule has 'warning' severity" do
      let(:rule_name) { "warning-rule" }

      it "returns 'warning'" do
        expect(subject).to eq("warning")
      end
    end

    context "when rule has 'info' severity" do
      let(:rule_name) { "info-rule" }

      it "returns 'info'" do
        expect(subject).to eq("info")
      end
    end

    context "when rule has 'hint' severity" do
      let(:rule_name) { "hint-rule" }

      it "returns 'hint'" do
        expect(subject).to eq("hint")
      end
    end

    context "when rule is not configured" do
      let(:rule_name) { "unconfigured-rule" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#rule_options" do
    subject { described_class.new(config).rule_options(rule_name) }

    let(:config) do
      {
        "linter" => {
          "rules" => {
            "hash-rule" => { "severity" => "error", "options" => { "style" => "double" } },
            "hash-no-options" => { "severity" => "warning" }
          }
        }
      }
    end

    context "when rule has options in hash configuration" do
      let(:rule_name) { "hash-rule" }

      it "returns the options" do
        expect(subject).to eq({ "style" => "double" })
      end
    end

    context "when rule has hash configuration without options" do
      let(:rule_name) { "hash-no-options" }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when rule is not configured" do
      let(:rule_name) { "unconfigured-rule" }

      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end
  end
end
