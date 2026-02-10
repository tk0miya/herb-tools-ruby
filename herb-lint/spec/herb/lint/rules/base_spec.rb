# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Lint::Rules::Base do
  let(:matcher) { build(:pattern_matcher) }

  describe ".rule_name" do
    subject { described_class.rule_name }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError, /must implement .rule_name/)
    end
  end

  describe ".description" do
    subject { described_class.description }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError, /must implement .description/)
    end
  end

  describe ".default_severity" do
    subject { described_class.default_severity }

    it "returns 'warning' as default" do
      expect(subject).to eq("warning")
    end
  end

  describe "#initialize" do
    context "with default values" do
      subject { described_class.new(matcher:) }

      it "uses default severity from class" do
        expect(subject.severity).to eq("warning")
      end
    end

    context "with custom values" do
      subject { described_class.new(severity: "error", matcher:) }

      it "uses provided values" do
        expect(subject.severity).to eq("error")
      end
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(nil, nil) }

    let(:matcher) { build(:pattern_matcher) }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError, /must implement #check/)
    end
  end

  describe "#create_offense" do
    subject { rule.create_offense(message: "Test message", location:) }

    let(:test_rule_class) do
      Class.new(described_class) do
        def self.rule_name
          "test-rule"
        end

        def self.description
          "A test rule"
        end
      end
    end
    let(:rule) { test_rule_class.new(severity: "error", matcher:) }
    let(:location) { build(:location) }

    it "creates an offense with correct attributes" do
      expect(subject).to be_a(Herb::Lint::Offense)
      expect(subject.rule_name).to eq("test-rule")
      expect(subject.message).to eq("Test message")
      expect(subject.severity).to eq("error")
      expect(subject.location).to eq(location)
    end
  end

  describe "subclass implementation" do
    subject { concrete_rule_class.new(matcher:) }

    let(:concrete_rule_class) do
      Class.new(described_class) do
        def self.rule_name
          "concrete-rule"
        end

        def self.description
          "A concrete rule for testing"
        end

        def self.default_severity
          "error"
        end

        def check(_document, _context)
          []
        end
      end
    end

    it "inherits properly and provides expected interface" do
      expect(concrete_rule_class.rule_name).to eq("concrete-rule")
      expect(concrete_rule_class.description).to eq("A concrete rule for testing")
      expect(concrete_rule_class.default_severity).to eq("error")
      expect(subject.severity).to eq("error")
      expect(subject.check(nil, nil)).to eq([])
    end
  end
end
