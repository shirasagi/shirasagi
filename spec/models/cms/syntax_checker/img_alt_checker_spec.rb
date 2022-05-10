require 'spec_helper'

describe Cms::SyntaxChecker::ImgAltChecker, type: :model, dbscope: :example do
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
      shared_examples "img's alt is missing or blank" do
        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq expected_img_html
            expect(error[:msg]).to eq I18n.t('errors.messages.set_img_alt')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_img_alt')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when alt is missing" do
        let(:img_html) { '<img src="/fs/1/1/1/_/logo.png">' }
        let(:img_htmls) { [ img_html ] }
        let(:expected_img_html) { img_html }

        it_behaves_like "img's alt is missing or blank"
      end

      context "when only alt is present" do
        let(:img_html) { '<img alt src="/fs/1/1/1/_/logo.png">' }
        let(:img_htmls) { [ img_html ] }
        let(:expected_img_html) { '<img alt="" src="/fs/1/1/1/_/logo.png">' }

        it_behaves_like "img's alt is missing or blank"
      end

      context "when alt is blank" do
        let(:img_html) { '<img alt="" src="/fs/1/1/1/_/logo.png">' }
        let(:img_htmls) { [ img_html ] }
        let(:expected_img_html) { img_html }

        it_behaves_like "img's alt is missing or blank"
      end

      context "when alt contains filename" do
        let(:img_html) { '<img alt="logo.png" src="/fs/1/1/1/_/logo.png">' }
        let(:img_htmls) { [ img_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq img_html
            expect(error[:msg]).to eq I18n.t('errors.messages.alt_is_included_in_filename')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.alt_is_included_in_filename')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end
    end

    context "with multiple img tags" do
      let(:img_html1) { '<img src="/fs/1/1/1/_/logo.png">' }
      let(:img_html2) { '<img alt="logo.png" src="/fs/1/1/1/_/logo.png">' }
      let(:img_html3) { '<img alt="ロゴ画像" src="/fs/1/1/1/_/logo.png">' }
      let(:img_htmls) { [ img_html1, img_html2, img_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq img_html1
          expect(error[:msg]).to eq I18n.t('errors.messages.set_img_alt')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_img_alt')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq img_html2
          expect(error[:msg]).to eq I18n.t('errors.messages.alt_is_included_in_filename')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.alt_is_included_in_filename')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
