require 'spec_helper'

describe "gws_affair_duty_hours", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:affair_start_at_hour) { "7時" }
  let(:affair_end_at_hour) { "16時" }

  let(:affair_break_start_at_minute) { "0分" }
  let(:affair_break_end_at_minute) { "15分" }

  let(:in_attendance_time_change_hour) { "0時" }

  before do
    login_gws_user
  end

  context 'crud for default item' do
    it do
      visit gws_affair_duty_hours_path(site: site)
      click_on I18n.t("gws/affair.default_duty_hour")

      expect(page).to have_css("#addon-basic dd", text: "8時 30分 ～ 17時 0分 （休憩 12時 15分 ～ 13時 0分 ）")
      expect(page).to have_css("#addon-basic dd", text: "3 時")
      expect(site.attendance_time_changed_minute).to eq 180

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select affair_start_at_hour, from: "item[affair_start_at_hour]"
        select affair_end_at_hour, from: "item[affair_end_at_hour]"

        select affair_break_start_at_minute, from: "item[affair_break_start_at_minute]"
        select affair_break_end_at_minute, from: "item[affair_break_end_at_minute]"

        select in_attendance_time_change_hour, from: "item[in_attendance_time_change_hour]"

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Affair::DutyHour.all.count).to eq 0
      expect(page).to have_css("#addon-basic dd", text: "7時 30分 ～ 16時 0分 （休憩 12時 0分 ～ 13時 15分 ）")
      expect(page).to have_css("#addon-basic dd", text: "0 時")

      site.reload
      expect(site.attendance_time_changed_minute).to eq 0
    end
  end
end
