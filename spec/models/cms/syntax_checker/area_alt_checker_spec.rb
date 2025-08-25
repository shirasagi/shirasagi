require 'spec_helper'

describe Cms::SyntaxChecker::AreaAltChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{area_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
    end
    let(:context) do
      Cms::SyntaxChecker::CheckerContext.new(
        cur_site: cms_site, cur_user: cms_user, contents: [ content ], html: raw_html, fragment: fragment, idx: idx)
    end

    context "with single area" do
      shared_examples "area's alt is missing or blank" do
        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to eq expected_area_html
            expect(error.full_message).to eq I18n.t('errors.messages.set_area_alt')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
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

      context "when alt is short" do
        let(:area_html) { '<area alt="エリア">' }
        let(:area_htmls) { [ area_html ] }
        let(:expected_area_html) { area_html }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to eq expected_area_html
            expect(error.full_message).to eq I18n.t('errors.messages.alt_too_short', count: 4)
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end
    end

    context "with multiple area tags" do
      let(:area_html1) { '<area>' }
      let(:area_html2) { '<area alt="">' }
      let(:area_html3) { '<area alt="Region">' }
      let(:area_htmls) { [ area_html1, area_html2, area_html3 ] }

      it do
        described_class.new.check(context, content)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error.id).to eq id
          expect(error.idx).to eq idx
          expect(error.code).to eq area_html1
          expect(error.full_message).to eq I18n.t('errors.messages.set_area_alt')
          expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
          expect(error.corrector).to be_blank
          expect(error.corrector_params).to be_blank
        end
        context.errors.second.tap do |error|
          expect(error.id).to eq id
          expect(error.idx).to eq idx
          expect(error.code).to eq area_html2
          expect(error.full_message).to eq I18n.t('errors.messages.set_area_alt')
          expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_area_alt')
          expect(error.corrector).to be_blank
          expect(error.corrector_params).to be_blank
        end
      end
    end

    context "with unfavorable words" do
      let!(:unfavorable_word) { create(:cms_unfavorable_word, cur_site: cms_site) }
      let(:words) { unfavorable_word.body.split(/\R+/) }
      let(:longest_word) { words.max_by(&:length) }
      let(:area_html1) { "<area alt=\"#{longest_word}\">" }
      let(:area_htmls) { [ area_html1 ] }

      it do
        described_class.new.check(context, content)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error.id).to eq id
          expect(error.idx).to eq idx
          expect(error.code).to eq area_html1
          expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
          expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
          expect(error.corrector).to be_blank
          expect(error.corrector_params).to be_blank
        end
      end
    end
  end
end
