require 'spec_helper'

describe Translate::RequestBuffer, dbscope: :example do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:source) { Translate::Lang.site(site).find_by(code: "ja") }
  let(:target) { Translate::Lang.site(site).find_by(code: "en") }

  let(:item) do
    Translate::RequestBuffer.new(
      site, source, target,
      array_size_limit: 10,
      text_size_limit: 10,
      contents_size_limit: 10
    )
  end
  let(:contents) { %w(first second third) }

  before do
    site.translate_state = "enabled"
    site.translate_api = "mock"
    site.translate_source = lang_ja
    site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)
    site.update!
  end

  context "mock develop" do
    before do
      mock = SS::Config.translate.mock
      mock["processor"] = "develop"
      SS::Config.replace_value_at(:translate, 'mock', mock)
    end

    it do
      item.push contents[0], 0
      item.push contents[1], 1
      item.push contents[2], 2
      translated = item.translate

      expect(translated.keys).to eq [0, 1, 2]
      expect(translated[0].map(&:text)).to eq ["[en:first]"]
      expect(translated[1].map(&:text)).to eq ["[en:second]"]
      expect(translated[2].map(&:text)).to eq ["[en:third]"]
    end
  end

  context "mock loopback" do
    before do
      mock = SS::Config.translate.mock
      mock["processor"] = "loopback"
      SS::Config.replace_value_at(:translate, 'mock', mock)
    end

    it do
      item.push contents[0], 0
      item.push contents[1], 1
      item.push contents[2], 2
      translated = item.translate

      expect(translated.keys).to eq [0, 1, 2]
      expect(translated[0].map(&:text)).to eq ["first"]
      expect(translated[1].map(&:text)).to eq ["second"]
      expect(translated[2].map(&:text)).to eq ["third"]
    end
  end
end
