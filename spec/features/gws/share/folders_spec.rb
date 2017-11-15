require 'spec_helper'

describe "gws_share_folders", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_share_folder }
  let(:index_path) { gws_share_folders_path site, gws_user }
  let(:edit_path) { edit_gws_share_folder_path site, item }
  let(:show_path) { gws_share_folder_path site, item }
  let(:delete_path) { delete_gws_share_folder_path site, item }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit index_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#edit" do
      item
      visit edit_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end

    it "#show" do
      item
      visit show_path
      wait_for_ajax
      expect(page).to have_content(item.name)
    end
  end

  context "#delete with auth", js: true do
    before { login_gws_user }

    before do
      item
      item.class.create_download_directory(File.dirname(item.class.zip_path(item._id)))
      File.open(item.class.zip_path(item._id), "w").close
    end

    it "#delete" do
      expect(FileTest.exist?(item.class.zip_path(item._id))).to be_truthy
      visit delete_path
      within "form" do
        click_button "削除"
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: '保存しました。')
      expect(FileTest.exist?(item.class.zip_path(item._id))).to be_falsey
    end
  end
end
