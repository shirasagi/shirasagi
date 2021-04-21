require 'spec_helper'

describe Translate::Convertor, dbscope: :example do
  let(:ss_proj1) { ::File.read("spec/fixtures/translate/ss_proj1.html") }
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:source) { Translate::Lang.site(site).find_by(code: "ja") }
  let(:target) { Translate::Lang.site(site).find_by(code: "en") }

  before do
    mock = SS::Config.translate.mock
    mock["processor"] = "develop"
    SS::Config.replace_value_at(:translate, 'mock', mock)

    site.translate_state = "enabled"
    site.translate_api = "mock"
    site.translate_source = lang_ja
    site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)
    site.update!
  end

  it do
    item = Translate::Convertor.new(site, source, target)
    html = item.convert(ss_proj1)

    doc = Nokogiri.parse(html)
    texts = doc.search('//text()').map do |node|
      next if node.node_type != 3
      next if node.blank?
      node.content
    end.compact

    texts.each do |text|
      expect(text).to match(/^\[#{target.code}\:.+?\]/)
    end
  end
end
