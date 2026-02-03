# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Herb::Lint::Rules::ErbRightTrim do
  subject { described_class.new.check(document, context) }

  let(:document) { Herb.parse(template, track_whitespace: true) }
  let(:context) { build(:context) }

  describe ".rule_name" do
    it "returns 'erb-right-trim'" do
      expect(described_class.rule_name).to eq("erb-right-trim")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Enforce consistent use of right-trim marker")
    end
  end

  describe ".default_severity" do
    it "returns 'warning'" do
      expect(described_class.default_severity).to eq("warning")
    end
  end

  describe "#check" do
    context "when all tags use right-trim consistently" do
      let(:template) do
        <<~ERB
          <% if condition -%>
            <p>Content</p>
          <% end -%>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when all tags do not use right-trim consistently" do
      let(:template) do
        <<~ERB
          <% if condition %>
            <p>Content</p>
          <% end %>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when tags mix right-trim usage (majority without)" do
      let(:template) do
        <<~ERB
          <% if condition -%>
            <p>Content</p>
          <% end %>
          <% another_value %>
        ERB
      end

      it "reports an offense for the tag with right-trim" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-right-trim")
        expect(subject.first.message).to eq("Remove right-trim marker `-%>` for consistency")
      end
    end

    context "when tags mix right-trim usage (majority with)" do
      let(:template) do
        <<~ERB
          <% if condition -%>
            <p>Content</p>
          <% end %>
          <% another_value -%>
        ERB
      end

      it "reports an offense for the tag without right-trim" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-right-trim")
        expect(subject.first.message).to eq("Add right-trim marker `-%>` for consistency")
      end
    end

    context "when tags are evenly split" do
      let(:template) do
        <<~ERB
          <% value1 -%>
          <% value2 %>
        ERB
      end

      it "reports offense for tags with right-trim (prefers no trim)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Remove right-trim marker `-%>` for consistency")
      end
    end

    context "when only one ERB tag exists" do
      let(:template) { "<% value -%>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when output tags mix with control tags" do
      let(:template) do
        <<~ERB
          <% if condition -%>
            <%= value %>
          <% end -%>
        ERB
      end

      it "reports offense for output tag without right-trim" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to eq("Add right-trim marker `-%>` for consistency")
      end
    end

    context "when multiple inconsistent tags exist" do
      let(:template) do
        <<~ERB
          <% tag1 -%>
          <% tag2 %>
          <% tag3 %>
          <% tag4 -%>
        ERB
      end

      it "reports offenses for minority style" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message).uniq).to eq(["Remove right-trim marker `-%>` for consistency"])
      end
    end

    context "when no ERB tags exist" do
      let(:template) { "<div>Plain HTML</div>" }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end
  end
end
