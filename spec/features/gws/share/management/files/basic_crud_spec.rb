require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], deleted: Time.zone.now }

  before do
    folder.update_folder_descendants_file_info
    login_gws_user
  end

  describe "restore" do
    it do
      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size

      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name
      click_on I18n.t('ss.links.restore')

      within "form#item-form" do
        click_on I18n.t('ss.buttons.restore')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.restored'))
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      item.reload
      expect(item.deleted).to be_blank

      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size
    end
  end

  describe "hard delete" do
    it do
      folder.reload
      expect(folder.descendants_files_count).to eq 1
      expect(folder.descendants_total_file_size).to eq item.size

      visit gws_share_files_path(site: site)
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on I18n.t('ss.navi.trash')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      click_on item.name
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t('ss.buttons.delete')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      expect(Gws::Share::File.where(id: item.id)).to be_blank

      folder.reload
      expect(folder.descendants_files_count).to eq 0
      expect(folder.descendants_total_file_size).to eq 0
    end
  end
end
