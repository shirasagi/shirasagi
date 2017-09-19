require 'spec_helper'

describe "gws_schedule_search", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_path site }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit path
      expect(page).to have_css('.gws-schedule-search-users h2', text: I18n.t('gws/schedule.search_users'))
      expect(page).to have_css('.gws-schedule-search-times h2', text: I18n.t('gws/schedule.search_times'))

      fill_in 's[keyword]', with: gws_user.name
      first('.gws-schedule-search-users input[type=submit]').click
      expect(page).to have_css('#calendar-controller')

      visit path
      first('.gws-schedule-search-times input[type=submit]').click
      expect(page).to have_css('.gws-schedule-search-times-result')
    end
  end
end
