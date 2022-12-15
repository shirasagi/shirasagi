require 'spec_helper'

describe "gws_schedule_search_times", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_times_path site }
  let!(:facility) { create(:gws_facility_item) }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      click_on I18n.t("gws.apis.facilities.index")
      wait_for_cbox do
        expect(page).to have_css(".select-item", text: facility.name)
        click_on facility.name
      end
      within "form.search" do
        fill_in 's[start_on]', with: Time.zone.today.advance(days: 1).strftime("%Y/%m/%d")
        fill_in 's[end_on]', with: Time.zone.today.strftime("%Y/%m/%d")
        select '22:00', from: 's[min_hour]'
        select '8:00', from: 's[max_hour]'
        first('input[type=submit]').click
      end
      expect(page).to have_no_css('#errorExplanation')
      expect(page).to have_content(gws_user.name)
      expect(page).to have_content(facility.name)
      expect(page).to have_content(gws_user.model_name.human)
    end
  end
end
