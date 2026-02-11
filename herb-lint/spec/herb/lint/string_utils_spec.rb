# frozen_string_literal: true

RSpec.describe Herb::Lint::StringUtils do
  describe ".pluralize" do
    it "returns singular form for count of 1" do
      expect(described_class.pluralize(1, "file")).to eq("file")
    end

    it "returns plural form for count of 0" do
      expect(described_class.pluralize(0, "file")).to eq("files")
    end

    it "returns plural form for count greater than 1" do
      expect(described_class.pluralize(2, "error")).to eq("errors")
      expect(described_class.pluralize(10, "warning")).to eq("warnings")
    end

    it "handles different words" do
      expect(described_class.pluralize(1, "offense")).to eq("offense")
      expect(described_class.pluralize(5, "offense")).to eq("offenses")
    end
  end
end
