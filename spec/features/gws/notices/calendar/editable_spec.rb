require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  let(:name) { unique_id }
  let(:today) { Time.zone.today }
  let(:start_on) { today.beginning_of_month }
  let(:end_on) { today.end_of_month }
  let(:color) { "#481357" }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path

      within "#menu" do
        click_on I18n.t("ss.links.new")
      end
      within 'form#item-form' do
        fill_in "item[name]", with: name
        fill_in "item[start_on]", with: start_on
        fill_in "item[end_on]", with: start_on
        fill_in "item[color]", with: color + "\n"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".mod-gws-notice-calendar" do
        first(".index-cleander-link").click
      end
      # wait for ajax completion
      expect(page).to have_no_css('.fc-loading')
      expect(page).to have_no_css('.ss-base-loading')
      within "#content-navi" do
        expect(page).to have_link(folder.name)
      end
      within ".gws-schedule-box" do
        expect(page).to have_css(".fc-event-name", text: name)
      end
    end
  end
end
