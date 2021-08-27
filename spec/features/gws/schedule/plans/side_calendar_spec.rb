require 'spec_helper'

describe 'gws_schedule_plans', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now }
  let(:title) { now.strftime('%Y年 %1m月') }

  before { login_gws_user }

  describe "#4043" do
    it do
      visit gws_schedule_plans_path(site: site)

      within "#calendar" do
        expect(page).to have_css('.fc-toolbar h2', text: title)
        # click_on title
        first('.fc-toolbar h2').click
      end

      within ".gws-schedule-tool-calendars" do
        expect(page).to have_css(".xdsoft_month", text: now.strftime("%1m月"))

        within all(".xdsoft_calendar")[0] do
          first('[data-date="1"]', text: "1").click
        end
        expect(page).to have_css(".xdsoft_month", text: now.strftime("%1m月"))

        within all(".xdsoft_calendar")[1] do
          first('[data-date="1"]', text: "1").click
        end
        expect(page).to have_css(".xdsoft_month", text: now.advance(months: 1).strftime("%1m月"))

        within all(".xdsoft_calendar")[2] do
          first('[data-date="1"]', text: "1").click
        end
        expect(page).to have_css(".xdsoft_month", text: now.advance(months: 2).strftime("%1m月"))

        within all(".xdsoft_calendar")[3] do
          first('[data-date="1"]', text: "1").click
        end
        expect(page).to have_css(".xdsoft_month", text: now.advance(months: 3).strftime("%1m月"))
      end
    end
  end
end
