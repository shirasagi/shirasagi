require 'spec_helper'

describe Cms::SyntaxChecker::KanaCharacterChecker, type: :model, dbscope: :example do
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
      let(:text) { "ﾋﾗｶﾞﾅ" }
      let(:texts) { [ text ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq text
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_kana_character')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_kana_character')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { 'ﾀﾋﾟｵｶ' }
      let(:text2) { 'ｶﾝﾀﾞﾀ' }
      let(:text3) { "ギガンテス" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq [ text1, text2 ].join(",")
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_kana_character')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_kana_character')
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

    context "with single paragraph" do
      let(:text) { "ﾋﾗｶﾞﾅ" }
      let(:texts) { [ text ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to eq "<p>ヒラガナ</p>"
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { 'ﾀﾋﾟｵｶ' }
      let(:text2) { 'ｶﾝﾀﾞﾀ' }
      let(:text3) { "ギガンテス" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include("<p>タピオカ</p>", "<p>カンダタ</p>", "<p>ギガンテス</p>")
      end
    end
  end
end
