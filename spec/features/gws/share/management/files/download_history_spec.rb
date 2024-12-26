require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], deleted: Time.zone.now }

  before { login_gws_user }

  describe "download from history" do
    it do
      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name

      ensure_addon_opened "#addon-gws-agents-addons-share-history"
      within "#addon-gws-agents-addons-share-history" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download
      expect(File.size(downloads.first)).to eq item.size
      expect(Fs.compare_file_head(downloads.first, item.path)).to be_truthy
    end
  end
end
