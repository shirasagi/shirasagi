require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:facility) { create :gws_facility_item }

  describe "what facility_reservation is" do
    before { login_gws_user }

    context "without plan" do
      it do
        visit gws_schedule_facility_plans_path(site: site, facility: facility)
        click_on I18n.t("gws/schedule.links.add_plan")
        within "form#item-form" do
          click_on I18n.t('gws/schedule.facility_reservation.index')
        end
        wait_for_cbox do
          expect(page).to have_css(".gws-schedule-search", text: I18n.t('gws/schedule.facility_reservation.free'))
        end
      end
    end

    context "with simple plan" do
      let!(:item) do
        create(:gws_schedule_plan, facility_ids: [ facility.id ])
      end

      it do
        visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          click_on I18n.t('gws/schedule.facility_reservation.index')
        end
        wait_for_cbox do
          expect(page).to have_css(".gws-schedule-search", text: I18n.t('gws/schedule.facility_reservation.free'))
        end
      end
    end

    context "with multi-days plan" do
      let(:start_at) { Time.zone.now.change(hour: 10, minute: 0, second: 0) }
      let(:end_at) { start_at + 3.days }
      let!(:item) do
        create(:gws_schedule_plan, facility_ids: [ facility.id ], start_at: start_at, end_at: end_at)
      end

      it do
        visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          click_on I18n.t('gws/schedule.facility_reservation.index')
        end
        wait_for_cbox do
          expect(page).to have_css(".gws-schedule-search", text: I18n.t('gws/schedule.facility_reservation.free'))
        end
      end
    end

    context "with multi-days and repeated plan" do
      let(:start_at) { Time.zone.now.change(day: 4, hour: 10, minute: 0, second: 0) }
      let(:end_at) { start_at + 3.days }
      let(:repeat_start) { start_at.beginning_of_month }
      let(:repeat_end) { repeat_start + 12.months }
      let!(:item) do
        create(
          :gws_schedule_plan, facility_ids: [ facility.id ], start_at: start_at, end_at: end_at,
          repeat_type: "monthly", interval: 1, repeat_base: "date",
          repeat_start: repeat_start, repeat_end: repeat_end, wdays: []
        )
      end

      it do
        visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          click_on I18n.t('gws/schedule.facility_reservation.index')
        end
        wait_for_cbox do
          expect(page).to have_css(".gws-schedule-search", text: I18n.t('gws/schedule.facility_reservation.free'))
        end
      end
    end
  end
end
