# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Format::ElementAnalysis do
  describe "#fully_inline?" do
    subject { analysis.fully_inline? }

    context "when all fields are true" do
      let(:analysis) do
        described_class.new(open_tag_inline: true, element_content_inline: true, close_tag_inline: true)
      end

      it { is_expected.to be(true) }
    end

    context "when open_tag_inline is false" do
      let(:analysis) do
        described_class.new(open_tag_inline: false, element_content_inline: true, close_tag_inline: true)
      end

      it { is_expected.to be(false) }
    end

    context "when element_content_inline is false" do
      let(:analysis) do
        described_class.new(open_tag_inline: true, element_content_inline: false, close_tag_inline: true)
      end

      it { is_expected.to be(false) }
    end

    context "when close_tag_inline is false" do
      let(:analysis) do
        described_class.new(open_tag_inline: true, element_content_inline: true, close_tag_inline: false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe "#block_format?" do
    subject { analysis.block_format? }

    context "when element_content_inline is false" do
      let(:analysis) do
        described_class.new(open_tag_inline: true, element_content_inline: false, close_tag_inline: false)
      end

      it { is_expected.to be(true) }
    end

    context "when element_content_inline is true" do
      let(:analysis) do
        described_class.new(open_tag_inline: true, element_content_inline: true, close_tag_inline: true)
      end

      it { is_expected.to be(false) }
    end
  end
end
