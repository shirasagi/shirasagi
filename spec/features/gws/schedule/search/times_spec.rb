require 'spec_helper'

describe "gws_schedule_search_times", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:path) { gws_schedule_search_times_path site }
  let!(:facility) { create(:gws_facility_item) }
  let!(:facility2) { create(:gws_facility_item) }
  let!(:facility3) { create(:gws_facility_item) }
  let!(:count) { 2 }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      wait_cbox_open { click_on I18n.t("gws.apis.facilities.index") }
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

  context "with auth", js: true do
    before do
      login_gws_user
      @save_config = SS.config.gws.schedule
      config = { "search_times" => { 'max_facilities' => count } }
      SS.config.replace_value_at(:gws, :schedule, @save_config.merge(config))
    end

    after do
      SS.config.replace_value_at(:gws, :schedule, @save_config)
    end

    it "over facilities limit" do
      visit path
      wait_cbox_open { click_on I18n.t("gws.apis.facilities.index") }
      wait_for_cbox do
        find('#colorbox .index .list-head .checkbox input').click
        find('.select-items').click
      end
      within "form.search" do
        first('input[type=submit]').click
      end

      within "#errorExplanation" do
        expect(page).to have_text(I18n.t('gws.errors.plan_search.max_facilities', count: count))
      end
      expect(page).to have_selector('.gws-schedule-search-facilities tbody tr', count: count)
    end
  end
end
