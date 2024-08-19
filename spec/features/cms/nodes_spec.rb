require 'spec_helper'

describe "cms_nodes", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:item) { Cms::Node.last }
  subject(:index_path) { cms_nodes_path site.id }
  subject(:new_path) { new_cms_node_path site.id }
  subject(:show_path) { cms_node_path site.id, item }
  subject(:edit_path) { edit_cms_node_path site.id, item }
  subject(:delete_path) { delete_cms_node_path site.id, item }
  subject(:download_path) { download_cms_nodes_path site.id }
  subject(:import_path) { import_cms_nodes_path site.id }

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
      
      #download
      visit download_path

      find('input[value="ダウンロード"]').click
      wait_for_ajax

      csv = ::CSV.read(downloads.first, headers: true, encoding: 'UTF-8')
      row = csv[0]
      expect(row["﻿ファイル名"]).to eq item.basename

      # delete
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "import" do 
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/cms/node/import/ads.csv" 
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end
  end
end
