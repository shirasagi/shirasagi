require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name) { unique_id }
  let(:folder1) { create(:gws_notice_folder) }
  let(:folder2) { create(:gws_notice_folder) }

  let(:today) { Time.zone.today }
  let(:start_on1) { today.beginning_of_month }
  let(:end_on1) { today.end_of_month }
  let(:start_on2) { today.last_year.beginning_of_month }
  let(:end_on2) { today.last_year.end_of_month }

  let!(:item1) { create :gws_notice_post, folder: folder1, start_on: start_on1, end_on: end_on1 }
  let!(:item2) { create :gws_notice_post, folder: folder1, start_on: start_on2, end_on: end_on2 }
  let!(:item3) { create :gws_notice_post, folder: folder2, start_on: start_on1, end_on: end_on1 }
  let!(:item4) { create :gws_notice_post, folder: folder1 }

  let(:index_path) { gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        expect(page).to have_link(folder2.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_no_css(".fc-event-name", text: item2.name)
        expect(page).to have_css(".fc-event-name", text: item3.name)
        expect(page).to have_no_css(".fc-event-name", text: item4.name)
      end

      within "#content-navi" do
        click_on folder1.name
      end
      # wait for ajax completion
      wait_for_js_ready
      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        expect(page).to have_link(folder2.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_no_css(".fc-event-name", text: item2.name)
        expect(page).to have_no_css(".fc-event-name", text: item3.name)
        expect(page).to have_no_css(".fc-event-name", text: item4.name)
      end

      within "#content-navi" do
        click_on folder2.name
      end
      # wait for ajax completion
      wait_for_js_ready
      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        expect(page).to have_link(folder2.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_no_css(".fc-event-name", text: item1.name)
        expect(page).to have_no_css(".fc-event-name", text: item2.name)
        expect(page).to have_css(".fc-event-name", text: item3.name)
        expect(page).to have_no_css(".fc-event-name", text: item4.name)
      end

      within "#content-navi" do
        click_on I18n.t("gws/notice.all")
      end
      # wait for ajax completion
      wait_for_js_ready
      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        expect(page).to have_link(folder2.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_no_css(".fc-event-name", text: item2.name)
        expect(page).to have_css(".fc-event-name", text: item3.name)
        expect(page).to have_no_css(".fc-event-name", text: item4.name)
      end
    end
  end
end
