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

    before do
      site.update!(notice_calendar_menu_state: "hide")
    end

    it do
      login_user admin, to: gws_notice_main_path(site: site)
      wait_for_all_turbo_frames
      within ".current-navi" do
        expect(page).to have_no_css(".calendars")
      end
      within "[data-id='#{post.id}']" do
        expect(page).to have_no_css(".index-calendar-link")
      end

      visit gws_notice_editables_path(site: site, folder_id: '-', category_id: '-')
      wait_for_all_turbo_frames
      within "[data-id='#{post.id}']" do
        expect(page).to have_no_css(".index-calendar-link")
      end

      click_on post.name
      wait_for_all_turbo_frames
      expect(page).to have_no_css("#addon-gws-agents-addons-notice-calendar")

      click_on I18n.t("ss.links.edit")
      wait_for_all_turbo_frames
      expect(page).to have_no_css("#addon-gws-agents-addons-notice-calendar")
    end
  end
end
