require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:user1) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }
  let(:user2) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }

  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }

  let!(:user1_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user1, date: this_month
  end
  let!(:user2_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: this_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  describe 'lock and unlock' do
    it do
      expect(user1_this_month_time_card.unlocked?).to be_truthy
      expect(user2_this_month_time_card.unlocked?).to be_truthy

      visit gws_attendance_main_path(site)
      within first(".mod-navi") do
        click_on I18n.t('modules.gws/attendance/management/time_card')
      end

      within ".nav-menu" do
        click_on I18n.t("gws/attendance.links.lock")
      end
      within "form#item-form" do
        click_on I18n.t("gws/attendance.buttons.lock")
      end

      user1_this_month_time_card.reload
      user2_this_month_time_card.reload
      expect(user1_this_month_time_card.locked?).to be_truthy
      expect(user2_this_month_time_card.locked?).to be_truthy

      within first(".mod-navi") do
        click_on I18n.t('modules.gws/attendance/management/time_card')
      end
      within ".nav-menu" do
        click_on I18n.t("gws/attendance.links.unlock")
      end
      within "form#item-form" do
        click_on I18n.t("gws/attendance.buttons.unlock")
      end

      user1_this_month_time_card.reload
      user2_this_month_time_card.reload
      expect(user1_this_month_time_card.unlocked?).to be_truthy
      expect(user2_this_month_time_card.unlocked?).to be_truthy
    end
  end
end
