require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:facility) { create :gws_facility_item }

  describe "what all-day plan is" do
    let(:name) { unique_id }
    let(:start_on) { Time.zone.parse("2016/09/09") }
    let(:end_on) { Time.zone.parse("2016/09/11") }

    before { login_gws_user }

    it do
      visit gws_schedule_facility_plans_path(site: site, facility: facility)
      click_on I18n.t("gws/schedule.links.add_plan")
      wait_for_js_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        check "item_allday"
        fill_in_date "item[start_on]", with: start_on
        fill_in_date "item[end_on]", with: end_on
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css(".fc-title", text: name)

      expect(Gws::Schedule::Plan.all.count).to eq 1
      Gws::Schedule::Plan.all.first.tap do |plan|
        expect(plan.name).to eq name
        expect(plan.start_on).to eq start_on.to_date
        expect(plan.end_on).to eq end_on.to_date
        expect(plan.start_at).to eq start_on
        expect(plan.end_at).to eq end_on.end_of_day.change(usec: 0)
        expect(plan.allday).to eq "allday"
        expect(plan.facility_ids).to have(1).item
        expect(plan.facility_ids).to include(facility.id)
      end
    end
  end
end
