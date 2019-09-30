require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:group1) { create :cms_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{site.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: [ group1.id ] }
  let!(:user2) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: [ group2.id ] }

  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }

  let!(:user1_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user1, date: this_month
  end
  let!(:user2_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: this_month
  end

  before { login_user user }

  describe 'search' do
    xit do
      visit gws_attendance_main_path(site)
      within first(".mod-navi") do
        click_on I18n.t('modules.gws/attendance/management/time_card')
      end
      expect(page).to have_css(".list-item", count: 3)

      within ".index-search" do
        select group1.section_name, from: "s[group_id]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 1)

      month = I18n.l(this_month.to_date, format: :attendance_year_month)
      title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user1.name, month: month)
      expect(page).to have_css(".list-item", text: title)

      within ".index-search" do
        select group2.section_name, from: "s[group_id]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", count: 1)

      month = I18n.l(this_month.to_date, format: :attendance_year_month)
      title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user2.name, month: month)
      expect(page).to have_css(".list-item", text: title)
    end
  end
end
