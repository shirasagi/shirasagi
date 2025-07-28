require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_readables_path(site: site, folder_id: folder, category_id: '-') }

  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }
  let(:browsed) { { user.id => Time.zone.now.utc } }

  let!(:item1) { create :gws_notice_post, folder: folder, start_on: start_on, end_on: end_on }
  let!(:item2) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path

      within ".list-items" do
        within ".list-item.read" do
          expect(page).to have_link item2.name
        end
        within ".list-item.unread" do
          expect(page).to have_link item1.name
          expect(page).to have_css(".index-cleander-link")
          first(".index-cleander-link").click
        end
      end

      # wait for ajax completion
      wait_for_js_ready
      within "#content-navi" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: item1.name)
      end
    end
  end
end
