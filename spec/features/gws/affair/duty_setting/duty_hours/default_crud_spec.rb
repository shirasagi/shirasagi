require 'spec_helper'

describe "gws_affair_duty_hours", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:affair_start_at_hour) { I18n.t('gws/attendance.hour', count: 7) }
  let(:affair_end_at_hour) { I18n.t('gws/attendance.hour', count: 16) }
  let(:affair_break_start_at_minute) { I18n.t('gws/attendance.minute', count: 0) }
  let(:affair_break_end_at_minute) { I18n.t('gws/attendance.minute', count: 15) }
  let(:in_attendance_time_change_hour) { I18n.t('gws/attendance.hour', count: 0) }
  let(:label1) do
    "8:30 #{I18n.t("ss.wave_dash")} 17:00 ( #{I18n.t("gws/affair.breaktime")} 12:15 #{I18n.t("ss.wave_dash")} 13:00 )"
  end
  let(:label2) do
    "7:30 #{I18n.t("ss.wave_dash")} 16:00 ( #{I18n.t("gws/affair.breaktime")} 12:00 #{I18n.t("ss.wave_dash")} 13:15 )"
  end

  before { login_gws_user }

  context 'crud for default item' do
    it do
      visit gws_affair_duty_setting_duty_hours_path(site: site)
      click_on I18n.t("gws/affair.default_duty_hour")
      expect(page).to have_css("#addon-basic dd", text: label1)
      expect(page).to have_css("#addon-basic dd", text: I18n.t('gws/attendance.hour', count: 3))
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
      expect(page).to have_css("#addon-basic dd", text: label2)
      expect(page).to have_css("#addon-basic dd", text: I18n.t('gws/attendance.hour', count: 0))

      site.reload
      expect(site.attendance_time_changed_minute).to eq 0
    end
  end
end
