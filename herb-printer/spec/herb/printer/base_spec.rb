# frozen_string_literal: true

RSpec.describe Herb::Printer::Base do
  describe ".print" do
    context "when input is a ParseResult" do
      it "visits the root node" do
        result = Herb.parse("hello", track_whitespace: true)

        # Base with no overrides produces empty output (default visit methods only traverse)
        expect(described_class.print(result)).to eq("")
      end
    end

    context "when input is a Node" do
      it "visits the node" do
        result = Herb.parse("hello", track_whitespace: true)

        expect(described_class.print(result.value)).to eq("")
      end
    end

    context "when AST has parse errors and ignore_errors is false" do
      it "raises PrintError" do
        result = Herb.parse("<div><span></div>", track_whitespace: true)
        next if result.value.recursive_errors.empty?

        expect { described_class.print(result) }.to raise_error(Herb::Printer::PrintError)
      end
    end

    context "when AST has parse errors and ignore_errors is true" do
      it "does not raise an error" do
        result = Herb.parse("<div><span></div>", track_whitespace: true)
        next if result.value.recursive_errors.empty?

        expect { described_class.print(result, ignore_errors: true) }.not_to raise_error
      end
    end
  end

  describe "bare subclass with no overrides" do
    let(:subclass) { Class.new(described_class) }

    it "produces empty output" do
      result = Herb.parse("<div>Hello</div>", track_whitespace: true)

      expect(subclass.print(result)).to eq("")
    end
  end
end
