require 'spec_helper'

describe "multilingual_node_pages", dbscope: :example do
  let!(:site) { cms_site }
  let!(:lang_node) { create_once :multilingual_node_lang, site: cms_site, filename: "en", name: "英語" }
  let!(:lang) { lang_node.filename }

  let!(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let!(:native_item) { create(:article_page, cur_node: node) }

  let!(:show_path) { article_page_path site.id, node, native_item }
  let!(:en_index_path) { multilingual_node_pages_path site.id, node, native_item, lang }
  let!(:en_new_path) { new_multilingual_node_page_path site.id, node, native_item, lang }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      click_link lang_node.name

      expect(current_path).to eq en_index_path
    end

    it "#new" do
      visit en_new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq en_new_path
      expect(page).not_to have_css("form#item-form")
    end
  end
end
