require 'spec_helper'

describe "gws_notices_calendars", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  context "when notice_calendar_menu_label is changed" do
    let!(:folder) { create(:gws_notice_folder, cur_site: site, cur_user: admin) }
    let!(:post) do
      create(
        :gws_notice_post, cur_site: site, cur_user: admin, folder: folder,
        start_on: now.beginning_of_month, end_on: now.beginning_of_month.next_month)
    end
    let(:menu_label) { "calendar-#{unique_id}" }

    before do
      site.update!(notice_calendar_menu_label: menu_label)
    end

    it do
      login_user admin, to: gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      within ".current-navi" do
        expect(page).to have_css(".calendars", text: menu_label)
      end
      within ".breadcrumb" do
        expect(page).to have_css(".active", text: menu_label)
      end

      visit gws_notice_editables_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames

      click_on post.name
      wait_for_all_turbo_frames
      within "#addon-gws-agents-addons-notice-calendar" do
        expect(page).to have_css(".addon-head", text: menu_label)
      end

      click_on I18n.t("ss.links.edit")
      wait_for_all_turbo_frames
      within "#addon-gws-agents-addons-notice-calendar" do
        expect(page).to have_css(".addon-head", text: menu_label)
      end

      click_on I18n.t("ss.links.back_to_show")
      wait_for_all_turbo_frames

      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      within "[data-id='#{post.id}']" do
        expect(page).to have_css(".index-calendar-link[aria-label='#{menu_label}']")
      end
    end
  end
end
