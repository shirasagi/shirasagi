require 'spec_helper'

describe "cms_nodes", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:item) { Cms::Node.last }
  subject(:index_path) { cms_nodes_path site.id }
  subject(:new_path) { new_cms_node_path site.id }
  subject(:show_path) { cms_node_path site.id, item }
  subject(:edit_path) { edit_cms_node_path site.id, item }
  subject(:delete_path) { delete_cms_node_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#crud" do
      visit index_path

      # new
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")

      # show
      visit show_path
      expect(current_path).not_to eq sns_login_path

      # preview
      within "#addon-basic" do
        click_on I18n.t("ss.links.sp_preview")
      end
      switch_to_window(windows.last)
      wait_for_document_loading
      current_window.close if Capybara.javascript_driver == :chrome
      switch_to_window(windows.last)
      wait_for_document_loading

      # edit
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      # delete
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end
end
