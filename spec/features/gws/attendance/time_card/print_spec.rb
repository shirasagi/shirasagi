require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }
  let(:prev_month) { this_month - 1.month }
  let(:next_month) { this_month + 1.month }
  let!(:time_card_this_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: this_month
  end
  let!(:time_card_prev_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: prev_month
  end
  let!(:time_card_next_month) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user, date: next_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  context 'print' do
    xit do
      visit gws_attendance_main_path(site)

      within ".nav-operation" do
        click_on I18n.t("ss.buttons.print")
      end

      month = I18n.l(this_month.to_date, format: :attendance_year_month)
      title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user.name, month: month)
      expect(page).to have_css(".attendance-box-title", text: title)
    end
  end
end
