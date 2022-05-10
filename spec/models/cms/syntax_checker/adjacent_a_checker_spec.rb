require 'spec_helper'

describe Cms::SyntaxChecker::AdjacentAChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{a_htmls.join(separator)}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with multiple a tags" do
      let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:a_html3) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3 ] }

      context "when a tags are separated with '|'" do
        let(:separator) { " | " }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to include(a_html1, a_html2)
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_adjacent_a')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when a tags are not separated" do
        let(:separator) { "" }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to include(a_html1, a_html2)
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_adjacent_a')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when a tags are separated with <span>" do
        let(:separator) { "<span>|</span>" }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end
    end
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{a_htmls.join}</div>" }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }
    let(:params) { nil }

    context "when inner html is text" do
      let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:a_html3) { '<a href="/docs/2892.html">アクセシビリティ</a>' }
      let(:a_html4) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3, a_html4 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).not_to include('<a href="/docs/2892.html">利用規約</a>')
        expect(context.result).not_to include('<a href="/docs/2892.html">個人情報保護</a>')
        expect(context.result).not_to include('<a href="/docs/2892.html">アクセシビリティ</a>')
        expect(context.result).to include("<a href=\"/docs/2892.html\">利用規約個人情報保護アクセシビリティ</a>")
        expect(context.result).to include('<a href="/docs/2893.html">サイトマップ</a>')
      end
    end

    context "when inner html is html" do
      let(:a_html1) { '<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>' }
      let(:a_html2) { '<a href="/docs/2892.html"><div>テキスト</div></a>' }
      let(:a_htmls) { [ a_html1, a_html2 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).not_to include('<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>')
        expect(context.result).not_to include('<a href="/docs/2892.html"><div>テキスト</div></a>')
        expect(context.result).to include("<a href=\"/docs/2892.html\"><img src=\"/fs/3/2/1/_/banner.jpg\"><div>テキスト</div></a>")
      end
    end
  end
end
