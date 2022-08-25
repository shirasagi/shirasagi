require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:user1) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }
  let(:user2) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }

  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }
  let(:prev_month) { this_month - 1.month }
  let(:next_month) { this_month + 1.month }

  let!(:user1_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user1, date: this_month
  end
  let!(:user1_prev_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user1, date: prev_month
  end

  let!(:user2_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: this_month
  end
  let!(:user2_prev_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: prev_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  describe 'delete' do
    it do
      visit gws_attendance_main_path(site)
      within first(".mod-navi") do
        click_on I18n.t('modules.gws/attendance/management/time_card')
      end
      within ".gws-attendance-year-month-navi" do
        click_on I18n.t("gws/attendance.prev_month")
      end

      month = I18n.l(prev_month.to_date, format: :attendance_year_month)
      title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user1.name, month: month)
      click_on title

      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end

      expect { Gws::Attendance::TimeCard.find(user1_prev_month_time_card.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  describe 'delete all' do
    it do
      visit gws_attendance_main_path(site)
      within first(".mod-navi") do
        click_on I18n.t('modules.gws/attendance/management/time_card')
      end

      within ".list-head" do
        first("input[type='checkbox']").click

        page.accept_confirm do
          click_on I18n.t("ss.buttons.delete")
        end
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect { Gws::Attendance::TimeCard.find(user1_this_month_time_card.id) }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Gws::Attendance::TimeCard.find(user2_this_month_time_card.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
