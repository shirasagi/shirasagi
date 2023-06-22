require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }

  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }

  let!(:item1) do
    create(:gws_notice_post, start_on: start_on, end_on: end_on, folder: folder)
  end
  let!(:item2) do
    create(:gws_notice_post, start_on: start_on, end_on: end_on, folder: folder)
  end
  let!(:item3) do
    create(:gws_notice_post, start_on: start_on, end_on: end_on, folder: folder)
  end
  let!(:item4) do
    create(:gws_notice_post, start_on: start_on, end_on: end_on, folder: folder)
  end

  let(:index_path) { gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
      within "#content-navi" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_css(".fc-event-name", text: item2.name)
        expect(page).to have_css(".fc-event-name", text: item3.name)
        expect(page).to have_css(".fc-event-name", text: item4.name)
      end

      within "form.search" do
        fill_in "s[keyword]", with: item1.name
        click_on I18n.t('ss.buttons.search')
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
      within "#content-navi" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
        expect(page).to have_no_css(".fc-event-name", text: item2.name)
        expect(page).to have_no_css(".fc-event-name", text: item3.name)
        expect(page).to have_no_css(".fc-event-name", text: item4.name)
      end
    end
  end
end
