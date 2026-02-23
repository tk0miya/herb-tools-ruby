# frozen_string_literal: true

RSpec.describe Herb::Highlight::SyntaxRenderer do
  # Helper to strip ANSI escape sequences from a string
  def strip_ansi(str)
    str.gsub(/\e\[[^m]*m/, "")
  end

  # A minimal test theme that assigns distinct colors to each token type
  let(:test_theme) do
    {
      "TOKEN_HTML_TAG_START" => "#ff0000",
      "TOKEN_HTML_TAG_END" => "#00ff00",
      "TOKEN_HTML_DOCTYPE" => "#0000ff",
      "TOKEN_HTML_COMMENT_START" => "#aaaaaa",
      "TOKEN_HTML_COMMENT_END" => "#bbbbbb",
      "TOKEN_HTML_ATTRIBUTE_NAME" => "#cccccc",
      "TOKEN_HTML_ATTRIBUTE_VALUE" => "#dddddd",
      "TOKEN_ERB_START" => "#111111",
      "TOKEN_ERB_CONTENT" => "#222222",
      "TOKEN_ERB_END" => "#333333",
      "TOKEN_EQUALS" => "#444444",
      "TOKEN_QUOTE" => "#555555",
      "RUBY_KEYWORD" => "#666666"
    }
  end

  describe "#render" do
    subject { syntax_renderer.render(source) }

    context "with nil theme (no theme_name, no theme)" do
      let(:syntax_renderer) { described_class.new }
      let(:source) { "<div>hello</div>" }

      it { is_expected.to eq(source) }
    end

    context "with unregistered theme_name" do
      let(:syntax_renderer) { described_class.new(theme_name: "nonexistent-theme") }
      let(:source) { "<span>text</span>" }

      it { is_expected.to eq(source) }
    end

    context "with a pre-resolved theme hash" do
      let(:syntax_renderer) { described_class.new(theme: test_theme) }

      context "with '<div>'" do
        let(:source) { "<div>" }

        it "colors HTML tag start tokens" do
          expect(subject).to include("\e[38;2;255;0;0m<\e[0m")
        end

        it "colors the element name with TOKEN_HTML_TAG_START color" do
          expect(subject).to include("\e[38;2;255;0;0mdiv\e[0m")
        end

        it "colors HTML tag end tokens" do
          expect(subject).to include("\e[38;2;0;255;0m>\e[0m")
        end

        it "produces hex color escape sequences (24-bit true-color)" do
          expect(subject).to match(/\e\[38;2;\d+;\d+;\d+m/)
        end
      end

      context "with '<div class=\"foo\">'" do
        let(:source) { '<div class="foo">' }

        it "colors attribute names with TOKEN_HTML_ATTRIBUTE_NAME" do
          # 'class' should have TOKEN_HTML_ATTRIBUTE_NAME color (#cccccc → 204,204,204)
          expect(subject).to include("\e[38;2;204;204;204mclass\e[0m")
        end

        it "colors attribute values with TOKEN_HTML_ATTRIBUTE_VALUE" do
          # 'foo' inside quotes should have TOKEN_HTML_ATTRIBUTE_VALUE color (#dddddd → 221,221,221)
          expect(subject).to include("\e[38;2;221;221;221mfoo\e[0m")
        end
      end

      context "with '<div class=\"foo\">hello</div>'" do
        let(:source) { '<div class="foo">hello</div>' }

        it { expect(strip_ansi(subject)).to eq(source) }
      end

      context "with '<div>hello</div>'" do
        let(:source) { "<div>hello</div>" }

        it { expect(strip_ansi(subject)).to eq(source) }

        it "does not apply color to text content outside tags" do
          expect(subject).not_to match(/\e\[[^m]*mhello\e\[0m/)
        end
      end

      context "with '<%= @val %>'" do
        let(:source) { "<%= @val %>" }

        it "colors ERB start delimiters" do
          # '<%=' should have TOKEN_ERB_START color (#111111 → 17,17,17)
          expect(subject).to include("\e[38;2;17;17;17m<%=\e[0m")
        end

        it "colors ERB end delimiters" do
          # '%>' should have TOKEN_ERB_END color (#333333 → 51,51,51)
          expect(subject).to include("\e[38;2;51;51;51m%>\e[0m")
        end
      end

      context "with '<% if true %>'" do
        let(:source) { "<% if true %>" }

        it "colors Ruby keywords inside ERB content" do
          # 'if' should have RUBY_KEYWORD color (#666666 → 102,102,102)
          expect(subject).to include("\e[38;2;102;102;102mif\e[0m")
        end
      end

      context "with '<%= user %>'" do
        let(:source) { "<%= user %>" }

        it "colors Ruby identifiers inside ERB content with TOKEN_ERB_CONTENT" do
          # 'user' should have TOKEN_ERB_CONTENT color (#222222 → 34,34,34)
          expect(subject).to include("\e[38;2;34;34;34muser\e[0m")
        end
      end

      context "with '<!-- foo -->'" do
        let(:source) { "<!-- foo -->" }

        it "colors comment start delimiter with TOKEN_HTML_COMMENT_START color" do
          expect(subject).to include("\e[38;2;170;170;170m<!--\e[0m")
        end

        it "colors comment end delimiter with TOKEN_HTML_COMMENT_END color" do
          # '-->' should have TOKEN_HTML_COMMENT_END color (#bbbbbb → 187,187,187)
          expect(subject).to include("\e[38;2;187;187;187m-->\e[0m")
        end
      end

      context "with '<!-- hello world -->'" do
        let(:source) { "<!-- hello world -->" }

        it { expect(strip_ansi(subject)).to eq(source) }

        it "colors HTML comment content with TOKEN_HTML_COMMENT_START color" do
          # 'hello' inside comment should inherit TOKEN_HTML_COMMENT_START color (#aaaaaa → 170,170,170)
          expect(subject).to include("\e[38;2;170;170;170mhello\e[0m")
        end
      end

      context "with '<a href=\"url\">'" do
        let(:source) { '<a href="url">' }

        it "colors = in attribute assignment with TOKEN_EQUALS" do
          # '=' should have TOKEN_EQUALS color (#444444 → 68,68,68)
          expect(subject).to include("\e[38;2;68;68;68m=\e[0m")
        end

        it "colors quote characters in tags with TOKEN_QUOTE" do
          # '"' should have TOKEN_QUOTE color (#555555 → 85,85,85)
          expect(subject).to include("\e[38;2;85;85;85m\"\e[0m")
        end
      end

      context "with '<br />'" do
        let(:source) { "<br />" }

        it "handles self-closing tags" do
          expect(strip_ansi(subject)).to eq(source)
        end
      end

      context "with '</div>'" do
        let(:source) { "</div>" }

        it { expect(strip_ansi(subject)).to eq(source) }

        it "colors '</' with TOKEN_HTML_TAG_START color" do
          expect(subject).to include("\e[38;2;255;0;0m</\e[0m")
        end
      end

      context "with named colors in theme" do
        let(:syntax_renderer) { described_class.new(theme: named_theme) }
        let(:source) { "<div>" }

        let(:named_theme) do
          {
            "TOKEN_HTML_TAG_START" => "cyan",
            "TOKEN_HTML_TAG_END" => "green"
          }
        end

        it "produces named ANSI codes" do
          # 'cyan' → \e[36m
          expect(subject).to include("\e[36m<\e[0m")
        end
      end
    end

    context "with a registered theme_name" do
      let(:syntax_renderer) { described_class.new(theme_name: "test-registered") }
      let(:source) { "<div>" }

      before do
        Herb::Highlight::Themes.register("test-registered", test_theme)
      end

      it "looks up and applies the registered theme" do
        expect(subject).to include("\e[38;2;255;0;0m<\e[0m")
      end
    end
  end
end
