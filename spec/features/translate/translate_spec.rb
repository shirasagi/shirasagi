require 'spec_helper'

describe "translate/public_filter", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:lang_ko) { create :translate_lang_ko }
  let!(:lang_zh_CN) { create :translate_lang_zh_cn }
  let!(:lang_zh_TW) { create :translate_lang_zh_tw }

  let(:part) { create :translate_part_tool, cur_site: site, filename: "tool" }
  let(:layout) { create_cms_layout part }
  let(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }

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
  let(:item) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: page_html }

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

  describe "translate public filter" do
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
