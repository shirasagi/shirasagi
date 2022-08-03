require 'spec_helper'

describe Translate::RequestBuffer, dbscope: :example, translate: true do
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
  let(:requests) { [] }

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
