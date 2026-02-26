# frozen_string_literal: true

RSpec.describe Herb::Core::AST do
  let(:host) { Class.new { include Herb::Core::AST }.new }

  describe "#comment_node?" do
    subject { host.comment_node?(node) }

    context "with an HTMLCommentNode" do
      let(:node) do
        Herb.parse("<!-- a comment -->", track_whitespace: true).value.children
            .find { _1.is_a?(Herb::AST::HTMLCommentNode) }
      end

      it { is_expected.to be true }
    end

    context "with an ERB comment node (<%# ... %>)" do
      let(:node) do
        Herb.parse("<%# an erb comment %>", track_whitespace: true).value.children
            .find { _1.is_a?(Herb::AST::ERBContentNode) }
      end

      it { is_expected.to be true }
    end

    context "with a regular ERB output node (<%= ... %>)" do
      let(:node) do
        Herb.parse("<%= value %>", track_whitespace: true).value.children
            .find { _1.is_a?(Herb::AST::ERBContentNode) }
      end

      it { is_expected.to be false }
    end

    context "with an HTMLElementNode" do
      let(:node) do
        Herb.parse("<div></div>", track_whitespace: true).value.children
            .find { _1.is_a?(Herb::AST::HTMLElementNode) }
      end

      it { is_expected.to be false }
    end
  end
end
