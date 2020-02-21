require 'spec_helper'

describe "mail_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :mail_page_node_page, filename: "node", name: "article" }
  let(:item) { create(:mail_page_page, cur_node: node) }
  let(:index_path) { mail_page_pages_path site.id, node }
  let(:new_path) { new_mail_page_page_path site.id, node }
  let(:show_path) { mail_page_page_path site.id, node, item }
  let(:edit_path) { edit_mail_page_page_path site.id, node, item }
  let(:delete_path) { delete_mail_page_page_path site.id, node, item }
  let(:copy_path) { copy_mail_page_page_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end
end
