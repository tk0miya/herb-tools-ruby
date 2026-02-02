# frozen_string_literal: true

require "spec_helper"

RSpec.describe Herb::Lint::Rules::VisitorRule do
  let(:test_rule_class) do
    Class.new(described_class) do
      def self.rule_name
        "test-visitor-rule"
      end

      def self.description
        "A test visitor rule"
      end

      def self.default_severity
        "error"
      end
    end
  end

  describe "#check" do
    let(:document) { Herb.parse(template, track_whitespace: true) }
    let(:context) { instance_double(Object) }

    context "when no visit methods are overridden" do
      subject { test_rule_class.new.check(document, context) }

      let(:template) { "<div><p>Hello</p></div>" }

      it "returns empty array (no offenses)" do
        expect(subject).to eq([])
      end
    end

    context "when visit method is overridden" do
      subject { element_counting_rule.new.check(document, context) }

      let(:template) { "<div><p>Hello</p><span>World</span></div>" }
      let(:element_counting_rule) do
        Class.new(described_class) do
          def self.rule_name
            "element-counter"
          end

          def self.description
            "Counts elements"
          end

          def visit_html_element_node(node)
            add_offense(message: "Found element", location: node.location)
            super
          end
        end
      end

      it "collects offenses from visited nodes" do
        expect(subject.size).to eq(3)
        expect(subject.map(&:message)).to all(eq("Found element"))
        expect(subject.map(&:rule_name)).to all(eq("element-counter"))
      end
    end

    context "when rule checks specific attribute" do
      subject { img_alt_rule.new.check(document, context) }

      let(:img_alt_rule) do
        Class.new(described_class) do
          def self.rule_name
            "img-alt"
          end

          def self.description
            "Require alt on img"
          end

          def visit_html_element_node(node)
            if node.tag_name.value == "img"
              attrs = node.open_tag.children.select { |c| c.is_a?(Herb::AST::HTMLAttributeNode) }
              has_alt = attrs.any? do |attr|
                attr.name.children.first.content == "alt"
              end
              add_offense(message: "Missing alt attribute", location: node.location) unless has_alt
            end
            super
          end
        end
      end

      context "with img missing alt" do
        let(:template) { '<img src="test.png">' }

        it "reports an offense" do
          expect(subject.size).to eq(1)
          expect(subject.first.message).to eq("Missing alt attribute")
        end
      end

      context "with img having alt" do
        let(:template) { '<img src="test.png" alt="Test image">' }

        it "reports no offenses" do
          expect(subject).to be_empty
        end
      end
    end
  end
end
