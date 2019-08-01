require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }

  before { login_gws_user }

  describe "disable(soft delete) all" do
    it do
      expect(item.deleted).to be_blank

      visit index_path
      find('.list-head label.check input').set(true)
      within ".list-head-action" do
        page.accept_confirm do
          # find('.disable-all').click
          click_on I18n.t("ss.links.delete")
        end
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      within "#gws-share-file-folder-list .tree-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end

      item.reload
      expect(item.deleted).to be_present
    end
  end
end
