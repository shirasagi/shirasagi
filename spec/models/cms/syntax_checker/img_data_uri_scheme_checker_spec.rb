require 'spec_helper'

describe Cms::SyntaxChecker::ImgDataUriSchemeChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{img_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single img" do
      context "when src is data-url" do
        let(:img_html) { '<img src="data:video/webm;base64,SGVsbG8sIFdvcmxkIQ==">' }
        let(:img_htmls) { [ img_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq img_html
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_img_scheme')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_img_scheme')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when src is path" do
        let(:img_html) { '<img src="/fs/1/1/1/_/logo.png">' }
        let(:img_htmls) { [ img_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to be_blank
        end
      end
    end

    context "with multiple img tags" do
      let(:img_html1) { '<img src="data:video/webm;base64,SGVsbG8sIFdvcmxkIQ==">' }
      let(:img_html2) { '<img src="/fs/1/1/1/_/logo.png">' }
      let(:img_html3) { '<img src="//example.jp/fs/1/1/1/_/logo.png">' }
      let(:img_htmls) { [ img_html1, img_html2, img_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq img_html1
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_img_scheme')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_img_scheme')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
