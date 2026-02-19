# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Html::NoDuplicateMetaNames do
  describe ".rule_name" do
    it "returns 'html-no-duplicate-meta-names'" do
      expect(described_class.rule_name).to eq("html-no-duplicate-meta-names")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Disallow duplicate meta elements with the same name attribute")
    end
  end

  describe ".default_severity" do
    it "returns 'error'" do
      expect(described_class.default_severity).to eq("error")
    end
  end

  describe "#check" do
    subject { described_class.new(matcher:).check(document, context) }

    let(:matcher) { build(:pattern_matcher) }
    let(:document) { Herb.parse(source, track_whitespace: true) }
    let(:context) { build(:context) }

    # Good examples from documentation
    context "with unique meta names in head (documentation example)" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="Welcome to our site">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with same meta name in different if/else branches (documentation example)" do
      let(:source) do
        <<~ERB
          <head>
            <% if mobile? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% else %>
              <meta name="viewport" content="width=1024">
            <% end %>
          </head>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "with duplicate meta name in head (documentation example)" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="viewport" content="width=1024">
          </head>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to include('Duplicate `<meta>` tag with `name="viewport"`')
        expect(subject.first.message).to include("Meta names should be unique within the `<head>` section.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with duplicate meta http-equiv in head (documentation example)" do
      let(:source) do
        <<~HTML
          <head>
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta http-equiv="X-UA-Compatible" content="chrome=1">
          </head>
        HTML
      end

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to include('Duplicate `<meta>` tag with `http-equiv="X-UA-Compatible"`')
        expect(subject.first.message).to include("`http-equiv` values should be unique within the `<head>` section.")
        expect(subject.first.severity).to eq("error")
      end
    end

    context "with meta before if and same meta inside if branch (documentation example)" do
      let(:source) do
        <<~ERB
          <head>
            <meta name="viewport" content="width=1024">

            <% if mobile? %>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <% else %>
              <meta http-equiv="refresh" content="30">
            <% end %>
          </head>
        ERB
      end

      it "reports an offense for the meta inside the if branch" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="viewport"`')
        expect(subject.first.message).to include("Meta names should be unique within the `<head>` section.")
      end
    end

    # Additional edge case tests
    context "when meta tags are outside <head>" do
      let(:source) do
        <<~HTML
          <meta name="description" content="Page description">
          <meta name="description" content="Duplicate">
        HTML
      end

      it "does not report an offense (metas outside head are ignored)" do
        expect(subject).to be_empty
      end
    end

    context "when all meta names are unique in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="Page description">
            <meta name="viewport" content="width=device-width">
            <meta name="author" content="John">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when there are duplicate meta names in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="First">
            <meta name="description" content="Second">
          </head>
        HTML
      end

      it "reports an offense for the duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("html-no-duplicate-meta-names")
        expect(subject.first.message).to include('`name="description"`')
        expect(subject.first.severity).to eq("error")
      end
    end

    context "when the same meta name appears three times in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="First">
            <meta name="description" content="Second">
            <meta name="description" content="Third">
          </head>
        HTML
      end

      it "reports an offense for each duplicate" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:message)).to all(include('`name="description"`'))
      end
    end

    context "when meta elements have no trackable attribute" do
      let(:source) do
        <<~HTML
          <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when meta name attribute has empty value" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="" content="First">
            <meta name="" content="Second">
          </head>
        HTML
      end

      it "does not report an offense (empty names are not tracked)" do
        expect(subject).to be_empty
      end
    end

    context "when meta names differ only in case" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="Description" content="First">
            <meta name="description" content="Second">
          </head>
        HTML
      end

      it "reports an offense (case-insensitive comparison)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="description"`')
      end
    end

    context "when non-meta elements have the same name attribute" do
      let(:source) do
        <<~HTML
          <head>
            <input name="email" type="text">
            <input name="email" type="hidden">
          </head>
        HTML
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with nested meta elements in head" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="description" content="First">
            <title>Page</title>
            <meta name="description" content="Second">
          </head>
        HTML
      end

      it "reports an offense for the nested duplicate" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="description"`')
        expect(subject.first.line).to eq(4)
      end
    end

    context "when meta http-equiv attribute has empty value" do
      let(:source) do
        <<~HTML
          <head>
            <meta http-equiv="" content="First">
            <meta http-equiv="" content="Second">
          </head>
        HTML
      end

      it "does not report an offense (empty http-equiv values are not tracked)" do
        expect(subject).to be_empty
      end
    end

    context "when meta http-equiv values differ only in case" do
      let(:source) do
        <<~HTML
          <head>
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta http-equiv="x-ua-compatible" content="chrome=1">
          </head>
        HTML
      end

      it "reports an offense (case-insensitive comparison)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`http-equiv="x-ua-compatible"`')
      end
    end

    context "when meta has same name but different media values" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=device-width" media="screen">
            <meta name="viewport" content="width=1024" media="print">
          </head>
        HTML
      end

      it "does not report an offense (different media values are not duplicates)" do
        expect(subject).to be_empty
      end
    end

    context "when meta has same name and same media value" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=device-width" media="screen">
            <meta name="viewport" content="width=1024" media="screen">
          </head>
        HTML
      end

      it "reports an offense (same media value makes them duplicates)" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="viewport"`')
      end
    end

    context "when meta has media value and the other does not" do
      let(:source) do
        <<~HTML
          <head>
            <meta name="viewport" content="width=device-width" media="screen">
            <meta name="viewport" content="width=1024">
          </head>
        HTML
      end

      it "does not report an offense (media presence mismatch means they are not duplicates)" do
        expect(subject).to be_empty
      end
    end

    context "with same meta name in different elsif branches" do
      let(:source) do
        <<~ERB
          <head>
            <% if desktop? %>
              <meta name="viewport" content="width=1280">
            <% elsif tablet? %>
              <meta name="viewport" content="width=768">
            <% else %>
              <meta name="viewport" content="width=device-width">
            <% end %>
          </head>
        ERB
      end

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "with duplicate meta name within the same if branch" do
      let(:source) do
        <<~ERB
          <head>
            <% if mobile? %>
              <meta name="viewport" content="width=device-width">
              <meta name="viewport" content="width=360">
            <% end %>
          </head>
        ERB
      end

      it "reports an offense for the duplicate within the same branch" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="viewport"`')
        expect(subject.first.message).to include("within the same control flow branch")
      end
    end

    context "with duplicate meta name within the same loop iteration" do
      let(:source) do
        <<~ERB
          <head>
            <% items.each do |item| %>
              <meta name="viewport" content="a">
              <meta name="viewport" content="b">
            <% end %>
          </head>
        ERB
      end

      it "reports an offense for the duplicate within the same loop iteration" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="viewport"`')
        expect(subject.first.message).to include("within the same loop iteration")
      end
    end

    context "with meta name in loop body not duplicating outer meta" do
      let(:source) do
        <<~ERB
          <head>
            <meta name="description" content="Site description">
            <% items.each do |item| %>
              <meta name="viewport" content="<%= item %>">
            <% end %>
          </head>
        ERB
      end

      it "does not report an offense (loop body is not checked against outer scope)" do
        expect(subject).to be_empty
      end
    end

    context "with nested conditional and same meta name propagated to outer scope" do
      let(:source) do
        <<~ERB
          <head>
            <% if a? %>
              <% if b? %>
                <meta name="viewport" content="nested">
              <% end %>
            <% else %>
              <meta name="viewport" content="outer-else">
            <% end %>
            <meta name="viewport" content="after-conditional">
          </head>
        ERB
      end

      it "reports an offense for the meta after the conditional" do
        expect(subject.size).to eq(1)
        expect(subject.first.message).to include('`name="viewport"`')
      end
    end
  end
end
