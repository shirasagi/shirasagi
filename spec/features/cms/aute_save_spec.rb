require 'spec_helper'

describe "aute_save" , type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:group) { cms_group }
  let(:item) { create(:article_page, cur_node: node) }
  subject(:event_node) { create(:event_node_page, group_ids: [group.id]) }
  subject(:event_item) { create(:event_page, cur_node: event_node) }
  subject(:faq_node) { create(:faq_node_page, group_ids: [group.id]) }
  subject(:faq_item) { create(:faq_page, cur_node: faq_node) }


  let(:article_index_path) { article_pages_path site.id, node }
  let(:article_new_path) { new_article_page_path site.id, node }
  let(:article_edit_path) { edit_article_page_path site.id, node, item }
  let(:article_show_path) { article_page_path site.id, node, item }

  let(:page_index_path) {cms_pages_path site.id }
  let(:page_new_path) {new_cms_page_path site.id }
  let(:page_edit_path) {edit_cms_page_path site.id, item }
  let(:page_show_path) {cms_page_path site.id,item }

  let(:event_index_path) {event_pages_path site.id, event_node }
  let(:event_new_path) {new_event_page_path site.id, event_node }
  let(:event_edit_path) {edit_event_page_path site.id, event_node, event_item }
  let(:event_show_path) { event_page_path site.id, event_node, event_item }

  let(:category_index_path) {category_nodes_path site.id, node }
  let(:category_new_path) {new_category_node_path site: site, cid: node_root.id }
  let(:category_edit_path) {edit_category_node_path site.id, node, item }
  let(:category_show_path) { category_node_path site.id, node, item }

  let(:faq_index_path) {faq_pages_path site.id, faq_node }
  let(:faq_new_path) {new_faq_page_path site.id, faq_node }
  let(:faq_edit_path) {edit_faq_page_path site.id, faq_node, faq_item }
  let(:faq_show_path) { faq_page_path site.id, faq_node, faq_item }

  before { login_cms_user }

  context "記事ページ" do
    it "new" do
      visit article_new_path
      fill_in "item[name]", with: "sample"
      sleep(5)
      visit article_index_path
      expect(current_path).to eq article_index_path

      click_on I18n.t("ss.links.new")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq article_new_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq article_new_path
      expect(page).to have_content("sample")
    end
    it "edit" do
      visit article_edit_path
      fill_in "item[name]", with: "サンプルタイトル"
      sleep(5)
      visit article_show_path
      expect(current_path).to eq article_show_path

      click_on I18n.t("ss.links.edit")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq article_edit_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq article_new_path
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "固定ページ" do
    it "new" do
      visit page_new_path
      fill_in "item[name]", with: "sample"
      sleep(5)
      visit page_index_path
      expect(current_path).to eq page_index_path

      click_on I18n.t("ss.links.new")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq page_new_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq page_new_path
      expect(page).to have_content("sample")
    end
    it "edit" do
      visit page_edit_path
      fill_in "item[name]", with: "サンプルタイトル"
      sleep(5)
      visit page_show_path
      expect(current_path).to eq page_show_path

      click_on I18n.t("ss.links.edit")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq page_edit_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq page_new_path
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "FAQページ" do
    it "new" do
      visit faq_new_path
      fill_in "item[name]", with: "sample"
      sleep(5)
      visit faq_index_path
      expect(current_path).to eq faq_index_path

      click_on I18n.t("ss.links.new")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq faq_new_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq faq_new_path
      expect(page).to have_content("sample")
    end
    it "edit" do
      visit faq_edit_path
      fill_in "item[name]", with: "サンプルタイトル"
      sleep(5)
      visit faq_show_path
      expect(current_path).to eq faq_show_path

      click_on I18n.t("ss.links.edit")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq faq_edit_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq faq_new_path
      expect(page).to have_content("サンプルタイトル")
    end
  end

  context "イベントページ" do
    it "new" do
      visit event_new_path
      fill_in "item[name]", with: "sample"
      sleep(5)
      visit event_index_path
      expect(current_path).to eq event_index_path

      click_on I18n.t("ss.links.new")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq event_new_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq event_new_path
      expect(page).to have_content("sample")
    end
    it "edit" do
      visit event_edit_path
      fill_in "item[name]", with: "サンプルタイトル"
      sleep(5)
      visit event_show_path
      expect(current_path).to eq event_show_path

      click_on I18n.t("ss.links.edit")
      page.accept_confirm(I18n.t("ss.confirm.resume_editing"));
      expect(current_path).to eq event_edit_path
      sleep(10)
      click_button I18n.t('ss.buttons.publish_save')
      sleep(10)
      expect(current_path).not_to eq event_new_path
      expect(page).to have_content("サンプルタイトル")
    end
  end
end
