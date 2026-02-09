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

    context "when both files.include and linter.include are configured" do
      let(:config) do
        {
          "files" => {
            "include" => ["**/*.xml.erb", "custom/**/*.html"]
          },
          "linter" => {
            "include" => ["**/*.html.erb"]
          }
        }
      end

      it "merges patterns from both sections" do
        expect(subject).to eq(["**/*.xml.erb", "custom/**/*.html", "**/*.html.erb"])
      end
    end

    context "when only files.include is configured" do
      let(:config) do
        {
          "files" => {
            "include" => ["**/*.xml.erb", "custom/**/*.html"]
          }
        }
      end

      it "returns patterns from files section" do
        expect(subject).to eq(["**/*.xml.erb", "custom/**/*.html"])
      end
    end

    context "when files section is empty" do
      let(:config) do
        {
          "files" => {},
          "linter" => {
            "include" => ["**/*.html.erb"]
          }
        }
      end

      it "returns patterns from linter section only" do
        expect(subject).to eq(["**/*.html.erb"])
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

    context "when both files.exclude and linter.exclude are configured" do
      let(:config) do
        {
          "files" => {
            "exclude" => ["vendor/**/*", "node_modules/**/*"]
          },
          "linter" => {
            "exclude" => ["tmp/**/*"]
          }
        }
      end

      it "uses linter.exclude only (override behavior)" do
        expect(subject).to eq(["tmp/**/*"])
      end
    end

    context "when only files.exclude is configured" do
      let(:config) do
        {
          "files" => {
            "exclude" => ["vendor/**/*", "node_modules/**/*"]
          }
        }
      end

      it "returns patterns from files section" do
        expect(subject).to eq(["vendor/**/*", "node_modules/**/*"])
      end
    end

    context "when files section is empty" do
      let(:config) do
        {
          "files" => {},
          "linter" => {
            "exclude" => ["tmp/**/*"]
          }
        }
      end

      it "returns patterns from linter section only" do
        expect(subject).to eq(["tmp/**/*"])
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

  describe "#disabled_rule_names" do
    subject { described_class.new(config).disabled_rule_names }

    context "when some rules are explicitly disabled" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "rule-a" => { "enabled" => false },
              "rule-b" => { "severity" => "error" },
              "rule-c" => { "enabled" => false, "severity" => "warning" },
              "rule-d" => { "enabled" => true }
            }
          }
        }
      end

      it "returns only the disabled rule names" do
        expect(subject).to contain_exactly("rule-a", "rule-c")
      end
    end

    context "when no rules are disabled" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "rule-a" => { "severity" => "error" },
              "rule-b" => { "enabled" => true }
            }
          }
        }
      end

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when rules section is empty" do
      let(:config) { { "linter" => { "rules" => {} } } }

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

  describe "#enabled_rule?" do
    subject { described_class.new(config).enabled_rule?(rule_name, **options) }

    let(:config) do
      {
        "linter" => {
          "rules" => {
            "enabled-rule" => { "enabled" => true },
            "disabled-rule" => { "enabled" => false },
            "unconfigured-rule" => { "severity" => "error" }
          }
        }
      }
    end
    let(:options) { {} }

    context "when rule is explicitly enabled" do
      let(:rule_name) { "enabled-rule" }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when rule is explicitly disabled" do
      let(:rule_name) { "disabled-rule" }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when rule has no enabled configuration" do
      let(:rule_name) { "unconfigured-rule" }

      it "returns true by default" do
        expect(subject).to be true
      end

      context "when default is false" do
        let(:options) { { default: false } }

        it "returns the specified default" do
          expect(subject).to be false
        end
      end
    end

    context "when rule is not configured at all" do
      let(:rule_name) { "totally-missing-rule" }

      it "returns true by default" do
        expect(subject).to be true
      end

      context "when default is false" do
        let(:options) { { default: false } }

        it "returns the specified default" do
          expect(subject).to be false
        end
      end
    end
  end

  describe "#fail_level" do
    subject { described_class.new(config).fail_level }

    context "when failLevel is configured" do
      let(:config) do
        {
          "linter" => {
            "failLevel" => "warning"
          }
        }
      end

      it "returns the configured fail level" do
        expect(subject).to eq("warning")
      end
    end

    context "when failLevel is not configured" do
      let(:config) { { "linter" => {} } }

      it "defaults to 'error'" do
        expect(subject).to eq("error")
      end
    end

    context "when linter section is missing" do
      let(:config) { {} }

      it "defaults to 'error'" do
        expect(subject).to eq("error")
      end
    end

    context "when failLevel is 'info'" do
      let(:config) do
        {
          "linter" => {
            "failLevel" => "info"
          }
        }
      end

      it "returns 'info'" do
        expect(subject).to eq("info")
      end
    end

    context "when failLevel is 'hint'" do
      let(:config) do
        {
          "linter" => {
            "failLevel" => "hint"
          }
        }
      end

      it "returns 'hint'" do
        expect(subject).to eq("hint")
      end
    end
  end
end
