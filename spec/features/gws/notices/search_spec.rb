require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item1) { create :gws_notice_post, folder: folder, readable_member_ids: [ gws_user.id ] }
  let!(:item2) { create :gws_notice_post, folder: folder, readable_member_ids: [ gws_user.id ] }

  before { login_gws_user }

  describe "search" do
    it do
      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      expect(page).to have_css(".list-item", text: item1.name)
      expect(page).to have_css(".list-item", text: item2.name)

      within "form.index-search" do
        fill_in "s[keyword]", with: item1.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", text: item1.name)
      expect(page).to have_no_css(".list-item", text: item2.name)

      within "form.index-search" do
        fill_in "s[keyword]", with: unique_id
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css(".list-item")
    end
  end
end
