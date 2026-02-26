# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Rewriter::StringRewriter do
  describe ".rewriter_name" do
    it "raises NotImplementedError" do
      expect { described_class.rewriter_name }.to raise_error(NotImplementedError)
    end
  end

  describe ".description" do
    it "raises NotImplementedError" do
      expect { described_class.description }.to raise_error(NotImplementedError)
    end
  end

  describe "#rewrite" do
    subject { described_class.new.rewrite(formatted, context) }

    let(:formatted) { "<p>hello</p>\n" }
    let(:context) { nil }

    it "raises NotImplementedError" do
      expect { subject }.to raise_error(NotImplementedError)
    end
  end
end
