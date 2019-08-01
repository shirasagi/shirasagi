require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], deleted: Time.zone.now }

  before { login_gws_user }

  describe "restore" do
    it do
      visit gws_share_files_path(site: site)
      click_on I18n.t('ss.navi.trash')
      click_on item.name
      click_on I18n.t('ss.links.restore')

      within "form" do
        click_on I18n.t('ss.buttons.restore')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.restored'))
      # within "#content-navi" do
      #   expect(page).to have_css(".tree-item", text: folder.name)
      # end

      item.reload
      expect(item.deleted).to be_blank
    end
  end

  describe "hard delete" do
    it do
      visit gws_share_files_path(site: site)
      click_on I18n.t('ss.navi.trash')
      click_on item.name
      click_on I18n.t('ss.links.delete')

      within "form" do
        click_on I18n.t('ss.links.delete')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      # within "#content-navi" do
      #   expect(page).to have_css(".tree-item", text: folder.name)
      # end

      expect(Gws::Share::File.where(id: item.id)).to be_blank
    end
  end
end
