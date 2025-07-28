require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name) { unique_id }
  let(:folder1) { create(:gws_notice_folder) }
  let(:folder2) { create(:gws_notice_folder) }
  let(:category1) { create :gws_notice_category, cur_site: site }
  let(:category2) { create :gws_notice_category, cur_site: site }

  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }

  let!(:item1) { create :gws_notice_post, folder: folder1, category_ids: [category1.id], start_on: start_on, end_on: end_on }
  let!(:item2) { create :gws_notice_post, folder: folder1, category_ids: [category2.id], start_on: start_on, end_on: end_on }
  let!(:item3) { create :gws_notice_post, folder: folder2, category_ids: [category1.id], start_on: start_on, end_on: end_on }
  let!(:item4) { create :gws_notice_post, folder: folder2, category_ids: [category2.id], start_on: start_on, end_on: end_on }

  let(:index_path) { gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      # wait for ajax completion
      wait_for_js_ready
      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        expect(page).to have_link(folder2.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_css(".fc-event-name", text: item2.name)
        expect(page).to have_css(".fc-event-name", text: item3.name)
        expect(page).to have_css(".fc-event-name", text: item4.name)
      end

      # select category1
      within ".gws-category-navi" do
        click_on I18n.t('gws.category')
        within ".dropdown-menu" do
          click_link category1.name
        end
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

      within "#content-navi" do
        expect(page).to have_link(folder1.name)
        click_link folder1.name
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
        expect(page).to have_link(folder2.name)
        click_link folder2.name
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
    end
  end
end
