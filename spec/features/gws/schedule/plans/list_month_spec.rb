require 'spec_helper'

describe "gws_schedule_csv", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:current) { Time.zone.now.beginning_of_month.since(8.days).beginning_of_week }

  let!(:plan0) { create :gws_schedule_plan, cur_site: site, start_at: current.since(2.days).change(hour: 9) }
  let!(:plan1) do
    at = current.since(3.days).beginning_of_day

    create(
      :gws_schedule_plan, cur_site: site,
      start_at: at, end_at: at.end_of_day, start_on: at, end_on: at, allday: "allday"
    )
  end
  let!(:plan_long) do
    at = current.since(4.days).beginning_of_day

    create(
      :gws_schedule_plan, cur_site: site,
      start_at: at, end_at: at.end_of_day, start_on: at, end_on: at + 3.weeks, allday: "allday"
    )
  end

  before { login_gws_user }

  it do
    visit gws_schedule_plans_path(site: site)
    within ".fc-toolbar" do
      click_on I18n.t("gws/schedule.calendar.buttonText.listMonth")
    end

    within ".fc-listMonth-view-table" do
      expect(page).to have_css(".fc-event", text: plan0.name)
      expect(page).to have_css(".fc-event", text: plan1.name)
      expect(page).to have_css(".fc-event", text: plan_long.name)

      expect(page).to have_selector(".fc-event", count: 3)
    end
  end
end
