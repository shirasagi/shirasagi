require 'spec_helper'

describe "gws_apis_reminders", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_plan_path site, item }
  let(:item) { create :gws_schedule_plan }

  context "create", js: true do
    before { login_gws_user }

    it "create" do
      visit path
      # Capybara::Poltergeist::TimeoutError
      # click_button "登録"
      within '#addon-gws-agents-addons-reminder div.gws-addon-reminder' do
        click_on '解除'
      end
      expect(page).to have_css('.gws-addon-reminder-label', text: I18n.t("gws.reminder.states.empty"))

      within '#addon-gws-agents-addons-reminder div.gws-addon-reminder' do
        fill_in 'item_date', with: (Time.zone.now + 2.hours).strftime('%Y/%m/%d %H:%M')
        click_on '登録'
      end
      expect(page).to have_css('.gws-addon-reminder-label', text: I18n.t("gws.reminder.states.entry"))
    end
  end
end
