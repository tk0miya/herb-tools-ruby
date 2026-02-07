# frozen_string_literal: true

RSpec.describe Herb::Config::Validator do
  let(:known_rules) { %w[html-alt-text html-attribute-quotes erb-no-debug] }

  describe "#valid?" do
    subject { described_class.new(config, known_rules:).valid? }

    context "with valid configuration" do
      let(:config) do
        {
          "linter" => {
            "enabled" => true,
            "include" => ["**/*.html.erb"],
            "exclude" => ["vendor/**"],
            "rules" => {
              "html-alt-text" => { "severity" => "error" },
              "html-attribute-quotes" => { "severity" => "warning", "options" => { "style" => "double" } }
            }
          },
          "formatter" => {
            "enabled" => false,
            "indentWidth" => 2,
            "maxLineLength" => 120
          }
        }
      end

      it { is_expected.to be true }
    end

    context "with empty configuration" do
      let(:config) { {} }

      it { is_expected.to be true }
    end

    context "with unknown rule name" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "unknown-rule" => { "severity" => "error" }
            }
          }
        }
      end

      it "is valid (unknown rules are warnings, not errors)" do
        expect(subject).to be true
      end
    end
  end

  describe "#validate!" do
    subject { described_class.new(config, known_rules:).validate! }

    context "with valid configuration" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "html-alt-text" => { "severity" => "error" }
            }
          }
        }
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "with invalid configuration" do
      let(:config) do
        {
          "linter" => {
            "enabled" => "yes",
            "rules" => {
              "html-alt-text" => { "severity" => "critical" }
            }
          }
        }
      end

      it "raises ValidationError with all errors" do
        expect { subject }.to raise_error(Herb::Config::ValidationError) do |error|
          expect(error.errors).to include(
            match(/The property 'linter\.enabled' of type string did not match.*type: boolean/),
            match(/value "critical" did not match one of the following values/)
          )
        end
      end
    end

    context "with unknown rule name" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "unknown-rule" => { "severity" => "error" }
            }
          }
        }
      end

      it "does not raise an error (unknown rules are warnings)" do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe "#errors" do
    subject { validator.errors }

    let(:validator) { described_class.new(config, known_rules:) }

    context "with valid configuration" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "html-alt-text" => { "severity" => "error" }
            }
          }
        }
      end

      it { is_expected.to be_empty }
    end

    context "with unknown rule" do
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "unknown-rule" => { "severity" => "error" }
            }
          }
        }
      end

      it "returns warning about unknown rule" do
        expect(subject).to include(match(/Warning:.*unknown rule 'unknown-rule'/))
      end
    end

    context "with multiple errors" do
      let(:config) do
        {
          "linter" => {
            "enabled" => "yes",
            "include" => "not-an-array",
            "rules" => {
              "html-alt-text" => { "severity" => "critical" }
            }
          },
          "formatter" => {
            "indentWidth" => -2
          }
        }
      end

      it "returns all validation errors" do
        expect(subject.size).to eq(4)
        expect(subject).to include(
          match(/The property 'linter\.enabled' of type string did not match.*type: boolean/),
          match(/The property 'linter\.include' of type string did not match.*type: array/),
          match(/value "critical" did not match one of the following values/),
          match(/did not have a minimum value of 1/)
        )
      end
    end

    context "when no known_rules provided" do
      let(:validator) { described_class.new(config, known_rules: []) }
      let(:config) do
        {
          "linter" => {
            "rules" => {
              "unknown-rule" => { "severity" => "error" }
            }
          }
        }
      end

      it "does not validate rule names" do
        expect(subject).to be_empty
      end
    end
  end
end
