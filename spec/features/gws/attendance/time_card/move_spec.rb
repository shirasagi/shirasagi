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

  context 'move next' do
    it do
      visit gws_attendance_main_path(site)

      within ".nav-group" do
        click_on I18n.t("gws/attendance.next_month")
      end
      within "table.time-card" do
        expect(page).to have_css(".date", text: I18n.l(next_month.to_date, format: :attendance_month_day))
        expect(page).to have_css(".date", text: I18n.l(next_month.end_of_month.to_date, format: :attendance_month_day))
      end

      within ".nav-group" do
        click_on I18n.t("gws/attendance.next_month")
      end
      expect(page).to have_content(I18n.t("gws/attendance.no_time_cards"))
    end
  end

  context 'move prev' do
    it do
      visit gws_attendance_main_path(site)

      within ".nav-group" do
        click_on I18n.t("gws/attendance.prev_month")
      end
      within "table.time-card" do
        expect(page).to have_css(".date", text: I18n.l(prev_month.to_date, format: :attendance_month_day))
        expect(page).to have_css(".date", text: I18n.l(prev_month.end_of_month.to_date, format: :attendance_month_day))
      end

      within ".nav-group" do
        click_on I18n.t("gws/attendance.prev_month")
      end
      expect(page).to have_content(I18n.t("gws/attendance.no_time_cards"))
    end
  end

  context 'select year/month' do
    it do
      visit gws_attendance_main_path(site)

      within ".nav-group" do
        select I18n.l(prev_month.to_date, format: :attendance_year_month), from: "year_month"
      end
      within "table.time-card" do
        expect(page).to have_css(".date", text: I18n.l(prev_month.to_date, format: :attendance_month_day))
        expect(page).to have_css(".date", text: I18n.l(prev_month.end_of_month.to_date, format: :attendance_month_day))
      end

      within ".nav-group" do
        select I18n.l(next_month.to_date, format: :attendance_year_month), from: "year_month"
      end
      within "table.time-card" do
        expect(page).to have_css(".date", text: I18n.l(next_month.to_date, format: :attendance_month_day))
        expect(page).to have_css(".date", text: I18n.l(next_month.end_of_month.to_date, format: :attendance_month_day))
      end
    end
  end
end
