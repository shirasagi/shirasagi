require 'spec_helper'

describe Cms::SyntaxChecker::AreaAltChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{area_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single img" do
      shared_examples "area's alt is missing or blank" do
        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq expected_area_html
            expect(error[:msg]).to eq I18n.t('errors.messages.set_area_alt')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when alt is missing" do
        let(:area_html) { '<area>' }
        let(:area_htmls) { [ area_html ] }
        let(:expected_area_html) { area_html }

        it_behaves_like "area's alt is missing or blank"
      end

      context "when only alt is present" do
        let(:area_html) { '<area alt />' }
        let(:area_htmls) { [ area_html ] }
        let(:expected_area_html) { '<area alt="">' }

        it_behaves_like "area's alt is missing or blank"
      end

      context "when alt is blank" do
        let(:area_html) { '<area alt="">' }
        let(:area_htmls) { [ area_html ] }
        let(:expected_area_html) { area_html }

        it_behaves_like "area's alt is missing or blank"
      end
    end

    context "with multiple img tags" do
      let(:area_html1) { '<area>' }
      let(:area_html2) { '<area alt="">' }
      let(:area_html3) { '<area alt="Region">' }
      let(:area_htmls) { [ area_html1, area_html2, area_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq area_html1
          expect(error[:msg]).to eq I18n.t('errors.messages.set_area_alt')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq area_html2
          expect(error[:msg]).to eq I18n.t('errors.messages.set_area_alt')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
