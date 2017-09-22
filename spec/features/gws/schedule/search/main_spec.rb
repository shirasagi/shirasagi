require 'spec_helper'

describe "gws_schedule_search", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:path) { gws_schedule_search_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit path
      click_on I18n.t('gws/schedule.tabs.search/users')
      expect(page).to have_css('.gws-schedule-search h2', text: I18n.t('gws/schedule.search_users'))

      within 'form.search' do
        fill_in 's[keyword]', with: gws_user.name
        click_on I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('#calendar-controller')

      visit path
      click_on I18n.t('gws/schedule.tabs.search/times')
      puts page.html
      expect(page).to have_css('.gws-schedule-search h2', text: I18n.t('gws/schedule.search_times'))
      within 'form.search' do
        click_on I18n.t('ss.buttons.search')
      end
      expect(page).to have_css('.gws-schedule-search-times-result')
    end
  end
end
