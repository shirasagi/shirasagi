require 'spec_helper'

describe "gws_bookmark_items", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:item1) { create :gws_bookmark_item, link_target: "_self" }
  let!(:item2) { create :gws_bookmark_item, link_target: "_blank" }
  let(:index_path) { gws_bookmark_main_path site }

  before { login_gws_user }

  context "basic crud" do
    it "#index" do
      visit index_path

      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')

      within ".index .list-items" do
        expect(page).to have_selector(".list-item a", text: item1.url)
        expect(page).to have_selector(".list-item a[target=\"_blank\"]", text: item2.url)
      end
    end

    it "#show" do
      visit gws_bookmark_item_path site, item1
      within "#addon-basic" do
        expect(page).to have_selector("a", text: item1.url)
      end
    end

    it "#show" do
      visit gws_bookmark_item_path site, item2
      within "#addon-basic" do
        expect(page).to have_selector("a[target=\"_blank\"]", text: item2.url)
      end
    end
  end
end
