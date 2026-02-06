# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Svg::TagNameCapitalization do
  describe ".rule_name" do
    it "returns 'svg-tag-name-capitalization'" do
      expect(described_class.rule_name).to eq("svg-tag-name-capitalization")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce correct capitalization of SVG element names")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    subject { described_class.new.check(document, context) }

    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    context "when SVG elements have correct capitalization" do
      let(:source) do
        <<~HTML
          <svg>
            <clipPath id="clip">
              <rect width="100" height="100"/>
            </clipPath>
            <linearGradient id="grad">
              <stop offset="0%" stop-color="red"/>
            </linearGradient>
          </svg>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when multiple SVG elements have incorrect capitalization" do
      let(:source) do
        <<~HTML
          <svg>
            <clippath id="clip">
              <rect width="100" height="100"/>
            </clippath>
            <lineargradient id="grad">
              <stop offset="0%" stop-color="red"/>
            </lineargradient>
          </svg>
        HTML
      end

      it "reports offenses for all incorrect elements" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to contain_exactly(
          "SVG element 'clippath' should be 'clipPath'",
          "SVG element 'lineargradient' should be 'linearGradient'"
        )
      end
    end

    context "when SVG filter elements are lowercase" do
      let(:source) do
        <<~HTML
          <svg>
            <filter>
              <feblend in="SourceGraphic"/>
              <fegaussianblur stdDeviation="5"/>
              <femerge>
                <femergenode/>
              </femerge>
            </filter>
          </svg>
        HTML
      end

      it "reports offenses for all incorrect filter elements" do
        expect(subject.size).to eq(4)
        expect(subject.map(&:message)).to contain_exactly(
          "SVG element 'feblend' should be 'feBlend'",
          "SVG element 'fegaussianblur' should be 'feGaussianBlur'",
          "SVG element 'femerge' should be 'feMerge'",
          "SVG element 'femergenode' should be 'feMergeNode'"
        )
      end
    end

    context "when elements are outside of SVG context" do
      let(:source) do
        <<~HTML
          <div>
            <clippath>Not SVG</clippath>
          </div>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when regular HTML elements inside SVG" do
      let(:source) do
        <<~HTML
          <svg>
            <div>Regular HTML</div>
          </svg>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when SVG elements have correct capitalization but mixed with incorrect ones" do
      let(:source) do
        <<~HTML
          <svg>
            <clipPath id="correct">
              <rect width="100" height="100"/>
            </clipPath>
            <lineargradient id="incorrect">
              <stop offset="0%" stop-color="red"/>
            </lineargradient>
          </svg>
        HTML
      end

      it "reports offense only for incorrect element" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("SVG element 'lineargradient' should be 'linearGradient'")
      end
    end

    context "when nested SVG elements" do
      let(:source) do
        <<~HTML
          <svg>
            <svg>
              <clippath id="nested">
                <rect width="100" height="100"/>
              </clippath>
            </svg>
          </svg>
        HTML
      end

      it "reports offense for nested elements" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("SVG element 'clippath' should be 'clipPath'")
      end
    end

    context "when SVG element is self-closing with incorrect capitalization" do
      let(:source) do
        <<~HTML
          <svg>
            <animatemotion/>
          </svg>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("SVG element 'animatemotion' should be 'animateMotion'")
      end
    end
  end
end
