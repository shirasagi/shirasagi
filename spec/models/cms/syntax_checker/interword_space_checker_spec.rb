require 'spec_helper'

describe Cms::SyntaxChecker::InterwordSpaceChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{texts.map { |text| "<p>#{text}</p>" }.join}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single paragraph" do
      context "with half-width space between half-width numerics" do
        let(:text) { "0123 4567" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with half-width space between half-width alphabets" do
        let(:text) { "abcd efg" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with half-width space between full-width strings" do
        let(:text) { "シラサギ 花子" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with full-width space between half-width numerics" do
        let(:text) { %w(0123 4567).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq text
            expect(error[:msg]).to eq I18n.t('errors.messages.check_interword_space')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with full-width space between half-width alphabets" do
        let(:text) { %w(aaa bbb).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq text
            expect(error[:msg]).to eq I18n.t('errors.messages.check_interword_space')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with full-width space between full-width strings" do
        let(:text) { %w(シラサギ 花子).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end
    end

    context "with multiple paragraph" do
      let(:text1) { "abcd efg" }
      let(:text2) { %w(aaa bbb).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
      let(:text3) { [ ss_japanese_text, ss_japanese_text ].join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq text2
          expect(error[:msg]).to eq I18n.t('errors.messages.check_interword_space')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{texts.map { |text| "<p>#{text}</p>" }.join}</div>" }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:params) { nil }
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }

    context "with space-separated alphabets" do
      let(:text1) { 'ＳＨＩＲＡＳＡＧＩ　ＴＡＲＯ' }
      let(:text2) { 'shirasagi　taro' }
      let(:text3) { 'シラサギ　太郎' }
      let(:text4) { 'Meta　の　Javascript　Ｗｅｂ　Ｆｒａｍｅｗｏｒｋ' }
      let(:texts) { [ text1, text2, text3, text4 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to \
          include("<p>ＳＨＩＲＡＳＡＧＩ　ＴＡＲＯ</p>", "<p>shirasagi taro</p>", "<p>シラサギ　太郎</p>", "<p>Meta の Javascript Ｗｅｂ　Ｆｒａｍｅｗｏｒｋ</p>")
      end
    end
  end
end
