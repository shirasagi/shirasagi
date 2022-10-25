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
        first('input[type=submit]').click
      end
      expect(page).to have_content(gws_user.name)
      expect(page).to have_content(facility.name)
      expect(page).to have_content(gws_user.model_name.human)
    end
  end
end
