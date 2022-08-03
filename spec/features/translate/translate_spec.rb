require 'spec_helper'

describe "translate/public_filter", type: :feature, dbscope: :example, js: true, translate: true do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let!(:part) { create :translate_part_tool, cur_site: site, filename: "tool" }
  let!(:layout) { create_cms_layout part }
  let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }

  let(:text1) { unique_id }
  let(:text2) { unique_id }
  let(:text3) { unique_id }
  let(:text4) { unique_id }

  let(:page_html) do
    html = []
    html << "<h2>#{text1}</h2>"
    html << "<p>#{text2}</p>"
    html << "<p>#{text3}<br>#{text4}</p>"
    html.join("\n")
  end
  let!(:item) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: page_html }

  context "with google" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
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

      ::FileUtils.rm_f(item.path)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it do
      visit item.full_url
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
      expect(page).to have_css("#translate-tool-1", text: lang_en.name)
      expect(page).to have_css("#translate-tool-1", text: lang_ko.name)
      expect(page).to have_css("#translate-tool-1", text: lang_zh_CN.name)
      expect(page).to have_css("#translate-tool-1", text: lang_zh_TW.name)

      select lang_en.name, from: "translate-tool-1"
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.show_original"))
      expect(page).to have_css("article.body", text: "[en:#{text1}]")
      expect(page).to have_css("article.body", text: "[en:#{text2}]")
      expect(page).to have_css("article.body", text: "[en:#{text3}]")
      expect(page).to have_css("article.body", text: "[en:#{text4}]")

      select lang_ko.name, from: "translate-tool-1"
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.show_original"))
      expect(page).to have_css("article.body", text: "[ko:#{text1}]")
      expect(page).to have_css("article.body", text: "[ko:#{text2}]")
      expect(page).to have_css("article.body", text: "[ko:#{text3}]")
      expect(page).to have_css("article.body", text: "[ko:#{text4}]")

      first('#translate-tool-1 option').select_option
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
    end
  end

  context "with azure (microsoft)" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
      WebMock.reset!

      install_azure_stubs

      site.translate_state = "enabled"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en, lang_ko, lang_zh_CN, lang_zh_TW].map(&:id)

      site.translate_api = "microsoft_translator_text"
      site.translate_microsoft_api_key = unique_id

      site.save!

      ::FileUtils.rm_f(item.path)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it do
      visit item.full_url
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
      expect(page).to have_css("#translate-tool-1", text: lang_en.name)
      expect(page).to have_css("#translate-tool-1", text: lang_ko.name)
      expect(page).to have_css("#translate-tool-1", text: lang_zh_CN.name)
      expect(page).to have_css("#translate-tool-1", text: lang_zh_TW.name)

      select lang_en.name, from: "translate-tool-1"
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.show_original"))
      expect(page).to have_css("article.body", text: "[en:#{text1}]")
      expect(page).to have_css("article.body", text: "[en:#{text2}]")
      expect(page).to have_css("article.body", text: "[en:#{text3}]")
      expect(page).to have_css("article.body", text: "[en:#{text4}]")

      select lang_ko.name, from: "translate-tool-1"
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.show_original"))
      expect(page).to have_css("article.body", text: "[ko:#{text1}]")
      expect(page).to have_css("article.body", text: "[ko:#{text2}]")
      expect(page).to have_css("article.body", text: "[ko:#{text3}]")
      expect(page).to have_css("article.body", text: "[ko:#{text4}]")

      first('#translate-tool-1 option').select_option
      expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
    end
  end
end
