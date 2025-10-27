require 'spec_helper'

describe "gws_notices_back_numbers", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  context "when notice_back_number_menu_label is changed" do
    let(:menu_label) { "back_number-#{unique_id}" }

    before do
      site.update!(notice_back_number_menu_label: menu_label)
    end

    it do
      login_user admin, to: gws_notice_back_numbers_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      within ".current-navi" do
        expect(page).to have_css(".back_numbers", text: menu_label)
      end
      within ".breadcrumb" do
        expect(page).to have_css(".active", text: menu_label)
      end
      within ".gws-notice-tabs" do
        expect(page).to have_css(".back_numbers", text: menu_label)
      end

      visit gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      within ".gws-notice-content-type-list" do
        expect(page).to have_css(".gws-notice-content-type-item", text: menu_label)
      end
    end
  end
end
