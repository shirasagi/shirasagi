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
      let(:text) { 'aaa　bbb' }
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
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end

    context "with multiple paragraph" do
      let(:text1) { "#{ss_japanese_text}　#{ss_japanese_text}" }
      let(:text2) { "#{ss_japanese_text} #{ss_japanese_text}" }
      let(:text3) { "#{ss_japanese_text}\u00a0#{ss_japanese_text}" }
      let(:texts) { [ text1, text2, text3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq text1
          expect(error[:msg]).to eq I18n.t('errors.messages.check_interword_space')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
