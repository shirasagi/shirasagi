require 'spec_helper'

describe Translate::Converter, dbscope: :example do
  let(:ss_proj1) { ::File.read("#{Rails.root}/spec/fixtures/translate/ss_proj1.html") }
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:source) { Translate::Lang.site(site).find_by(code: "ja") }
  let(:target) { Translate::Lang.site(site).find_by(code: "en") }
  let(:requests) { [] }

  before do
    @net_connect_allowed = WebMock.net_connect_allowed?
    WebMock.disable_net_connect!
    WebMock.reset!

    stub_request(:any, "https://oauth2.googleapis.com/token").to_return do |request|
      requests << request

      response = {
        "access_token": unique_id,
        "expires_in": 3920,
        "token_type": "Bearer",
        "scope": "https://www.googleapis.com/#{unique_id}",
        "refresh_token": unique_id
      }
      { status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' } }
    end
    stub_request(:any, "https://translate.googleapis.com/language/translate/v2").to_return do |request|
      requests << request

      body = JSON.parse(request.body)
      translations = body["q"].map do |text|
        { "translatedText" => "[#{target.code}:#{text}]", "detectedSourceLanguage" => source.code }
      end
      response = { "data" => { "translations" => translations } }
      { status: 200, body: response.to_json, headers: {'Content-Type' => 'application/json'} }
    end

    site.translate_state = "enabled"
    site.translate_source = lang_ja
    site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)

    site.translate_api = "google_translation"
    site.translate_google_api_project_id = "shirasagi-dev"
    site.translate_google_api_credential_file = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/translate/gcp_credential.json")

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

    texts.each do |text|
      expect(text).to match(/^\[#{target.code}:.+?\]/)
    end
  end
end
