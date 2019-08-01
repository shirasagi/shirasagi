require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }

  before { login_gws_user }

  describe "download from history" do
    it do
      visit index_path
      click_on item.name
      within "#addon-gws-agents-addons-share-history" do
        first(".addon-head h2").click
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download
      expect(downloads.first).to end_with("/#{item.filename}")
    end
  end
end
