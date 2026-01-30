# frozen_string_literal: true

RSpec.describe Herb::Lint::LinterIgnore do
  describe ".ignore_file?" do
    context "when source contains the ignore directive" do
      it "returns true for a standalone ignore comment" do
        source = "<%# herb:linter ignore %>"
        expect(described_class.ignore_file?(source)).to be true
      end

      it "returns true when the directive is among other content" do
        source = <<~ERB
          <div>Hello</div>
          <%# herb:linter ignore %>
          <img src="test.png">
        ERB
        expect(described_class.ignore_file?(source)).to be true
      end

      it "returns true with extra whitespace inside the comment" do
        source = "<%#   herb:linter   ignore   %>"
        expect(described_class.ignore_file?(source)).to be true
      end
    end

    context "when source does not contain the ignore directive" do
      it "returns false for an empty string" do
        expect(described_class.ignore_file?("")).to be false
      end

      it "returns false for regular ERB content" do
        source = '<img src="test.png" alt="test">'
        expect(described_class.ignore_file?(source)).to be false
      end

      it "returns false for a regular ERB comment" do
        source = "<%# just a comment %>"
        expect(described_class.ignore_file?(source)).to be false
      end

      it "returns false for an HTML comment with the directive text" do
        source = "<!-- herb:linter ignore -->"
        expect(described_class.ignore_file?(source)).to be false
      end

      it "returns false for a disable comment (not an ignore)" do
        source = "<%# herb:disable alt-text %>"
        expect(described_class.ignore_file?(source)).to be false
      end
    end
  end
end
