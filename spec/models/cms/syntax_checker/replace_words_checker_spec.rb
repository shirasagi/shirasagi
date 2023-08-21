require 'spec_helper'

describe Cms::SyntaxChecker::ReplaceWordsChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{texts.map { |text| "<p>#{text}</p>" }.join}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }
    let!(:word_dictionary) { create :cms_word_dictionary }

    context "with single paragraph" do
      let(:text) { "③Ⅲ③Ⅲ③Ⅲ" }
      let(:texts) { [ text ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "③"
          expect(error[:msg]).to eq I18n.t('errors.messages.replace_word', from: "③", to: "3")
          expect(error[:detail]).to be_blank
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(replace_from: "③", replace_to: "3")
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "Ⅲ"
          expect(error[:msg]).to eq I18n.t('errors.messages.replace_word', from: "Ⅲ", to: "3")
          expect(error[:detail]).to be_blank
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(replace_from: "Ⅲ", replace_to: "3")
        end
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { "③Ⅲ③Ⅲ③Ⅲ" }
      let(:text2) { '100㌘' }
      let(:text3) { "平成2年" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(3).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "③"
          expect(error[:msg]).to eq I18n.t('errors.messages.replace_word', from: "③", to: "3")
          expect(error[:detail]).to be_blank
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(replace_from: "③", replace_to: "3")
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "Ⅲ"
          expect(error[:msg]).to eq I18n.t('errors.messages.replace_word', from: "Ⅲ", to: "3")
          expect(error[:detail]).to be_blank
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(replace_from: "Ⅲ", replace_to: "3")
        end
        context.errors.third.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "㌘"
          expect(error[:msg]).to eq I18n.t('errors.messages.replace_word', from: "㌘", to: "グラム")
          expect(error[:detail]).to be_blank
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(replace_from: "㌘", replace_to: "グラム")
        end
      end
    end
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{texts.map { |text| "<p>#{text}</p>" }.join}</div>" }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }

    context "with single paragraph" do
      let(:text) { "③Ⅲ③Ⅲ③Ⅲ" }
      let(:texts) { [ text ] }

      context "when ③ is corrected" do
        let(:params) { { "replace_from" => "③", "replace_to" => "3" } }

        it do
          described_class.new.correct(context)
          expect(context.result).to eq "<p>3Ⅲ3Ⅲ3Ⅲ</p>"
        end
      end

      context "when Ⅲ is corrected" do
        let(:params) { { "replace_from" => "Ⅲ", "replace_to" => "3" } }

        it do
          described_class.new.correct(context)
          expect(context.result).to eq "<p>③3③3③3</p>"
        end
      end
    end

    context "with multiple paragraphs" do
      let(:text1) { "③Ⅲ③Ⅲ③Ⅲ" }
      let(:text2) { '100㌘' }
      let(:text3) { "平成2年" }
      let(:texts) { [ text1, text2, text3 ] }
      let(:params) { { "replace_from" => "㌘", "replace_to" => "グラム" } }

      it do
        described_class.new.correct(context)
        expect(context.result).to include("<p>#{text1}</p>", "<p>100グラム</p>", "<p>#{text3}</p>")
      end
    end
  end
end
