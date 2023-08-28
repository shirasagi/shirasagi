require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before do
    site.schedule_max_month = 3
    site.schedule_max_years = 1
    site.save!

    login_gws_user
  end

  context "when start_at is too far to reserve" do
    let(:start_at) { site.schedule_max_at.in_time_zone + 1.day }
    let(:end_at) { start_at + 1.hour }

    it do
      visit gws_schedule_plans_path(site: site)
      click_on I18n.t("gws/schedule.links.add_plan")

      within "#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in_datetime "item[start_at]", with: start_at
        fill_in_datetime "item[end_at]", with: end_at
        click_on I18n.t("ss.buttons.save")
      end
      err_msg = I18n.t('gws/schedule.errors.less_than_max_date', date: I18n.l(site.schedule_max_at, format: :long))
      expect(page).to have_css('#errorExplanation', text: err_msg)
    end
  end

  context "when end_at is at the limit" do
    let(:start_at) { end_at - 1.hour }
    let(:end_at) { site.schedule_max_at.in_time_zone.end_of_day }

    it do
      visit gws_schedule_plans_path(site: site)
      click_on I18n.t("gws/schedule.links.add_plan")

      within "#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in_datetime "item[start_at]", with: start_at
        fill_in_datetime "item[end_at]", with: end_at
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
