# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Herb::Lint::Severity do
  describe ".rank" do
    it "returns 4 for error" do
      expect(described_class.rank("error")).to eq(4)
    end

    it "returns 3 for warning" do
      expect(described_class.rank("warning")).to eq(3)
    end

    it "returns 2 for info" do
      expect(described_class.rank("info")).to eq(2)
    end

    it "returns 1 for hint" do
      expect(described_class.rank("hint")).to eq(1)
    end

    it "raises an error for unknown severity" do
      expect { described_class.rank("unknown") }.to raise_error(ArgumentError, /Unknown severity type: "unknown"/)
    end
  end
end
