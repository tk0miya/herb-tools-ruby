# frozen_string_literal: true

require_relative "../../../../spec_helper"

RSpec.describe Herb::Lint::Rules::Erb::PreferImageTagHelper do
  describe ".rule_name" do
    it "returns 'erb-prefer-image-tag-helper'" do
      expect(described_class.rule_name).to eq("erb-prefer-image-tag-helper")
    end
  end

  describe ".description" do
    it "returns description" do
      expect(described_class.description).to eq("Prefer Rails image_tag helper over raw <img> tags")
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

    # Good examples from documentation
    context "when using image_tag helper" do
      let(:source) { '<%= image_tag "logo.png", alt: "Logo" %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using image_tag with class attribute" do
      let(:source) { '<%= image_tag "banner.jpg", alt: "Banner", class: "hero-image" %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using image_tag with size attribute" do
      let(:source) { '<%= image_tag "icon.svg", alt: "Icon", size: "24x24" %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using image_tag with dynamic URL" do
      let(:source) { '<%= image_tag user.avatar.url, alt: "User avatar" %>' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using image_tag with interpolated URL" do
      let(:source) { '<%= image_tag "#{root_url}/banner.jpg", alt: "Banner" %>' } # rubocop:disable Lint/InterpolationCheck

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using static img tag without ERB" do
      let(:source) { '<img src="/static/logo.png" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using img with data URI and ERB" do
      let(:source) { '<img src="data:<%= base64_image %>" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using img with full URL and ERB" do
      let(:source) { '<img src="https://example.com/<%= image_path %>" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    context "when using img with http URL and ERB" do
      let(:source) { '<img src="http://example.com/<%= image_path %>" alt="Logo">' }

      it "does not report an offense" do
        expect(subject).to be_empty
      end
    end

    # Bad examples from documentation
    context "when using img with image_path helper" do
      let(:source) { '<img src="<%= image_path("logo.png") %>" alt="Logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
        expect(subject.first.message).to eq("Prefer using <%= image_tag %> helper instead of <img> tag")
        expect(subject.first.severity).to eq("warning")
      end
    end

    context "when using img with asset_path helper" do
      let(:source) { '<img src="<%= asset_path("banner.jpg") %>" alt="Banner">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with dynamic ERB expression" do
      let(:source) { '<img src="<%= user.avatar.url %>" alt="User avatar">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with ERB in path" do
      let(:source) { '<img src="<%= root_url %>/banner.jpg" alt="Banner">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with product.image" do
      let(:source) { '<img src="<%= product.image %>" alt="Product image">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with Rails.application.routes.url_helpers.root_url" do
      let(:source) { '<img src="<%= Rails.application.routes.url_helpers.root_url %>/icon.png" alt="Logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with admin_path in path" do
      let(:source) { '<img src="<%= admin_path %>/icon.png" alt="Admin icon">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with multiple ERB expressions" do
      let(:source) { '<img src="<%= base_url %><%= image_path("logo.png") %>" alt="Logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using img with root_path and string literal" do
      let(:source) { '<img src="<%= root_path %><%= "icon.png" %>" alt="Icon">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    # Edge cases not covered by documentation
    context "when using img with blob URL and ERB" do
      let(:source) { '<img src="blob:<%= blob_url %>" alt="Logo">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when using uppercase IMG tag with ERB" do
      let(:source) { '<IMG src="<%= image_path("logo.png") %>">' }

      it "reports an offense" do
        expect(subject.size).to eq(1)
        expect(subject.first.rule_name).to eq("erb-prefer-image-tag-helper")
      end
    end

    context "when multiple img tags with ERB exist" do
      let(:source) do
        <<~HTML
          <img src="<%= image_path('logo.png') %>">
          <img src="<%= asset_path('banner.jpg') %>" alt="Banner">
        HTML
      end

      it "reports an offense for each" do
        expect(subject.size).to eq(2)
        expect(subject.map(&:rule_name)).to all(eq("erb-prefer-image-tag-helper"))
        expect(subject.map(&:line)).to contain_exactly(1, 2)
      end
    end

    context "when mixing static img tags, ERB img tags, and image_tag helpers" do
      let(:source) do
        <<~ERB
          <%= image_tag 'logo.png' %>
          <img src="/static/banner.jpg">
          <img src="<%= image_path('icon.png') %>">
        ERB
      end

      it "reports offense only for ERB img tag" do
        expect(subject.size).to eq(1)
        expect(subject.first.line).to eq(3)
      end
    end

    context "with non-img elements" do
      let(:source) { '<div><p>Hello</p><a href="#">Link</a></div>' }

      it "does not report offenses" do
        expect(subject).to be_empty
      end
    end
  end
end
