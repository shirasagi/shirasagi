require 'spec_helper'

describe "multilingual_node_pages", dbscope: :example do
  let!(:site) { cms_site }
  let!(:lang_node) { create_once :multilingual_node_lang, filename: "en", name: "英語" }
  let!(:lang) { lang_node.filename }

  let!(:node) { create_once :faq_node_page, filename: "docs", name: "article" }
  let!(:native_item) { create(:faq_page, cur_node: node) }
  let!(:foreign_item) { create(:faq_page, filename: "#{lang}/#{native_item.filename}") }
  let!(:en_index_path) { multilingual_node_pages_path site.id, node, native_item, lang }
  let!(:en_new_path) { new_multilingual_node_page_path site.id, node, native_item, lang }
  let!(:en_show_path) { multilingual_node_page_path site.id, node, native_item, lang, foreign_item }
  let!(:en_edit_path) { edit_multilingual_node_page_path site.id, node, native_item, lang, foreign_item }
  let!(:en_delete_path) { delete_multilingual_node_page_path site.id, node, native_item, lang, foreign_item }

  context "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit en_show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit en_edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit en_delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq en_index_path
    end

  end
end
