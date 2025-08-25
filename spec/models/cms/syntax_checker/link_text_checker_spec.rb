require 'spec_helper'

describe Cms::SyntaxChecker::LinkTextChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{a_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
    end
    let(:context) do
      Cms::SyntaxChecker::CheckerContext.new(
        cur_site: cms_site, cur_user: cms_user, contents: [ content ], html: raw_html, fragment: fragment, idx: idx)
    end

    context "with single a" do
      context "when text length is 3" do
        let(:a_html) { '<a href="https://example.jp/">abc</a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to eq a_html
            expect(error.full_message).to eq I18n.t('errors.messages.link_text_too_short', count: 4)
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "when text length is 4" do
        let(:a_html) { '<a href="https://example.jp/">abcd</a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to be_blank
        end
      end

      context "when img's alt length is 3" do
        let(:a_html) { '<a href="https://example.jp/"><img src="/fs/1/1/1/_/thumb/logo.png" alt="abc"></a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to eq a_html
            expect(error.full_message).to eq I18n.t('errors.messages.link_text_too_short', count: 4)
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "when img's alt length is 4" do
        let(:a_html) { '<a href="https://example.jp/"><img src="/fs/1/1/1/_/thumb/logo.png" alt="abcd"></a>' }
        let(:a_htmls) { [ a_html ] }

        it do
          described_class.new.check(context, content)

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
        described_class.new.check(context, content)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error.id).to eq id
          expect(error.idx).to eq idx
          expect(error.code).to eq a_html1
          expect(error.full_message).to eq I18n.t('errors.messages.link_text_too_short', count: 4)
          expect(error.detail).to be_blank
          expect(error.corrector).to be_blank
          expect(error.corrector_params).to be_blank
        end
      end
    end

    context "with unfavorable words" do
      context "enabled" do
        let!(:unfavorable_word) { create(:cms_unfavorable_word, cur_site: cms_site) }
        let(:words) { unfavorable_word.body.split(/\R+/) }
        let(:longest_word) { words.max_by(&:length) }
        let(:a_html1) { "<a href=\"https://example.jp/\">#{longest_word}</a>" }
        let(:a_htmls) { [ a_html1 ] }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to eq a_html1
            expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "disabled" do
        let!(:unfavorable_word) { create(:cms_unfavorable_word, cur_site: cms_site, state: "disabled") }
        let(:words) { unfavorable_word.body.split(/\R+/) }
        let(:longest_word) { words.max_by(&:length) }
        let(:a_html1) { "<a href=\"https://example.jp/\">#{longest_word}</a>" }
        let(:a_htmls) { [ a_html1 ] }

        it do
          described_class.new.check(context, content)
          expect(context.errors).to be_blank
        end
      end
    end
  end
end
