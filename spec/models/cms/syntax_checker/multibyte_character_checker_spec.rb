require 'spec_helper'

describe Cms::SyntaxChecker::MultibyteCharacterChecker, type: :model, dbscope: :example do
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
      context "with full-width numerics" do
        let(:text) { %w(７６５４ ３２１０).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq %w(７６５４ ３２１０).join(",")
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with full-width alphabets" do
        let(:text) { %w(ＡＢＣＤ ＥＦＧ).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq %w(ＡＢＣＤ ＥＦＧ).join(",")
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with half-width alphabets and full-width space" do
        let(:text) { %w(abcd efg).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with only half-width numerics" do
        let(:text) { "0123 4567" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with only half-width alphabets" do
        let(:text) { "abcd efg" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)
          expect(context.errors).to be_blank
        end
      end

      context "with just two full-width alphabets" do
        let(:text) { "ＯＴ" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq text
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with only single full-width numeric" do
        let(:text) { "７" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq text
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "with just two full-width numeric2" do
        let(:text) { "７３" }
        let(:texts) { [ text ] }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq text
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
            expect(error[:collector]).to eq described_class.name
            expect(error[:collector_params]).to be_blank
          end
        end
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { 'ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ' }
      let(:text2) { 'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ' }
      let(:text3) { "zyxwvutsrqponmlkjihgfedcba" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq [ text1, text2 ].join(",")
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_multibyte_character')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character')
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
      let(:text) { "３２１０" }
      let(:texts) { [ text ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to eq "<p>3210</p>"
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { 'ＡＢＣＤＥＦＧ' }
      let(:text2) { 'ｔｕｖｗｘｙｚ' }
      let(:text3) { "gfedcba" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).to include("<p>ABCDEFG</p>", "<p>tuvwxyz</p>", "<p>gfedcba</p>")
      end
    end

    context "with space-separated alphabets" do
      let(:text1) { "ＳＨＩＲＡＳＡＧＩ#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}ＴＡＲＯ" }
      let(:text2) { "shirasagi#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}taro" }
      let(:text3) { "シラサギ#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}太郎" }
      let(:text4) { %w(Meta の Javascript Ｗｅｂ Ｆｒａｍｅｗｏｒｋ).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
      let(:texts) { [ text1, text2, text3, text4 ] }

      it do
        described_class.new.correct(context)
        [
          "<p>SHIRASAGI#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}TARO</p>", "<p>#{text2}</p>", "<p>#{text3}</p>",
          "<p>#{%w(Meta の Javascript Web Framework).join(Cms::SyntaxChecker::FULL_WIDTH_SPACE)}</p>"
        ].tap do |results|
          expect(context.result).to include(*results)
        end
      end
    end
  end
end
