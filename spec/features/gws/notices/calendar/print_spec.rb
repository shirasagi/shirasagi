require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:name) { unique_id }
  let(:folder) { create(:gws_notice_folder) }

  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }

  let!(:item) { create :gws_notice_post, folder: folder, start_on: start_on, end_on: end_on }

  let(:index_path) { gws_notice_calendars_path(site: site, folder_id: '-', category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      wait_for_all_turbo_frames
      within "#content-navi-core .gws-notice-folder" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item.name)
        within ".operations" do
          click_on I18n.t('ss.buttons.print')
        end
        # wait for ajax completion
        wait_for_js_ready
      end
      within "#main.print-preview" do
        within ".gws-schedule-box" do
          expect(page).to have_css(".fc-event-name", text: item.name)
        end
      end
    end
  end
end
