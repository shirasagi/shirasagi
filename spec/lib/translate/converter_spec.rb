require 'spec_helper'

describe Translate::Converter, dbscope: :example, translate: true do
  let(:ss_proj1) { File.read("#{Rails.root}/spec/fixtures/translate/ss_proj1.html") }
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:source) { Translate::Lang.site(site).find_by(code: "ja") }
  let(:target) { Translate::Lang.site(site).find_by(code: "en") }

  context "with google" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!
      WebMock.reset!

      install_google_stubs

      site.translate_state = "enabled"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)

      site.translate_api = "google_translation"
      site.translate_google_api_project_id = "shirasagi-dev"
      "#{Rails.root}/spec/fixtures/translate/gcp_credential.json".tap do |path|
        site.translate_google_api_credential_file = tmp_ss_file(contents: path)
      end

      site.save!
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it do
      item = Translate::Converter.new(site, source, target)
      html = item.convert(ss_proj1)

      doc = Nokogiri.parse(html)
      texts = doc.search('//text()').map do |node|
        next if node.node_type != 3
        next if node.blank?
        node.content
      end.compact
      expect(texts).to be_present

      texts.each do |text|
        expect(text).to match(/^\[#{target.code}:.+?\]/)
      end

      texts = []
      Translate::Converter::TEXT_ATTRS.each do |text_attr|
        doc.search("//*[@#{text_attr}]").each do |node|
          next if node.attributes[text_attr].blank?
          texts << node.attributes[text_attr]
        end
      end
      expect(texts).to be_present

      texts.each do |text|
        expect(text).to match(/^\[#{target.code}:.+?\]/)
      end
    end
  end

  context "with azure(microsoft)" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!
      WebMock.reset!

      install_azure_stubs

      site.translate_state = "enabled"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)

      site.translate_api = "microsoft_translator_text"
      site.translate_microsoft_api_key = unique_id

      site.save!
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it do
      item = Translate::Converter.new(site, source, target)
      html = item.convert(ss_proj1)

      doc = Nokogiri.parse(html)
      texts = doc.search('//text()').map do |node|
        next if node.node_type != 3
        next if node.blank?
        node.content
      end.compact
      expect(texts).to be_present

      texts.each do |text|
        expect(text).to match(/^\[#{target.code}:.+?\]/)
      end

      texts = []
      Translate::Converter::TEXT_ATTRS.each do |text_attr|
        doc.search("//*[@#{text_attr}]").each do |node|
          next if node.attributes[text_attr].blank?
          texts << node.attributes[text_attr]
        end
      end
      expect(texts).to be_present

      texts.each do |text|
        expect(text).to match(/^\[#{target.code}:.+?\]/)
      end
    end
  end
end
