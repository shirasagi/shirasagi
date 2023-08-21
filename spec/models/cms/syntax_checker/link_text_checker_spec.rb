require 'spec_helper'

describe Cms::SyntaxChecker::LinkTextChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{a_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single a" do
      context "when text length is 3" do
        let(:a_html) { '<a href="https://example.jp/">abc</a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq a_html
            expect(error[:msg]).to eq I18n.t('errors.messages.check_link_text')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_link_text')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when text length is 4" do
        let(:a_html) { '<a href="https://example.jp/">abcd</a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to be_blank
        end
      end

      context "when img's alt length is 3" do
        let(:a_html) { '<a href="https://example.jp/"><img src="/fs/1/1/1/_/thumb/logo.png" alt="abc"></a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq a_html
            expect(error[:msg]).to eq I18n.t('errors.messages.check_link_text')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_link_text')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when img's alt length is 4" do
        let(:a_html) { '<a href="https://example.jp/"><img src="/fs/1/1/1/_/thumb/logo.png" alt="abcd"></a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to be_blank
        end
      end
    end

    context "with multiple img tags" do
      let(:a_html1) { '<a href="https://example.jp/">abc</a>' }
      let(:a_html2) { '<a href="https://example.jp/">abcd</a>' }
      let(:a_html3) { '<a href="https://example.jp/"><img src="/fs/1/1/1/_/thumb/logo.png" alt="abcd"></a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq a_html1
          expect(error[:msg]).to eq I18n.t('errors.messages.check_link_text')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_link_text')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
