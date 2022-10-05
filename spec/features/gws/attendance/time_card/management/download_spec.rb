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
  let!(:user1_next_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user1, date: next_month
  end

  let!(:user2_this_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: this_month
  end
  let!(:user2_prev_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: prev_month
  end
  let!(:user2_next_month_time_card) do
    create :gws_attendance_time_card, :with_records, cur_site: site, cur_user: user2, date: next_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  describe 'download' do
    context "with no users" do
      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.download")
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.download")
        end

        msg = I18n.t(
          "errors.format",
          attribute: Gws::Attendance::DownloadParam.t(:user_ids),
          message: I18n.t("errors.messages.blank")
        )
        expect(page).to have_css("#errorExplanation", text: msg)
      end
    end

    context "with user1" do
      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.download")
        end

        within "form#item-form" do
          click_on I18n.t("ss.apis.users.index")
        end
        wait_for_cbox do
          click_on user1.long_name
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq this_month.end_of_month.day
          expect(csv[0][0]).to eq user1.uid
          expect(csv[0][1]).to eq user1.name
          expect(csv[0][2]).to eq this_month.to_date.iso8601
          expect(csv[-1][0]).to eq user1.uid
          expect(csv[-1][1]).to eq user1.name
          expect(csv[-1][2]).to eq this_month.end_of_month.to_date.iso8601
        end
      end
    end

    context "with user1 and custom term" do
      let(:from_time) { prev_month + 14.days }
      let(:to_time) { this_month + 13.days }

      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.download")
        end

        within "form#item-form" do
          click_on I18n.t("ss.apis.users.index")
        end
        wait_for_cbox do
          click_on user1.long_name
        end
        within "form#item-form" do
          fill_in "item[from_date]", with: I18n.l(from_time.to_date, format: :picker, locale: I18n.default_locale)
          fill_in "item[to_date]", with: I18n.l(to_time.to_date, format: :picker, locale: I18n.default_locale)
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq prev_month.end_of_month.day
          expect(csv[0][0]).to eq user1.uid
          expect(csv[0][1]).to eq user1.name
          expect(csv[0][2]).to eq from_time.to_date.iso8601
          expect(csv[-1][0]).to eq user1.uid
          expect(csv[-1][1]).to eq user1.name
          expect(csv[-1][2]).to eq to_time.to_date.iso8601
        end
      end
    end

    context "with user2 and UTF-8" do
      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        within ".nav-menu" do
          click_on I18n.t("ss.links.download")
        end

        within "form#item-form" do
          click_on I18n.t("ss.apis.users.index")
        end
        wait_for_cbox do
          click_on user2.long_name
        end
        within "form#item-form" do
          first("input[value='UTF-8']").click
          click_on I18n.t("ss.buttons.download")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq this_month.end_of_month.day
          expect(csv[0][0]).to eq user2.uid
          expect(csv[0][1]).to eq user2.name
          expect(csv[0][2]).to eq this_month.to_date.iso8601
          expect(csv[-1][0]).to eq user2.uid
          expect(csv[-1][1]).to eq user2.name
          expect(csv[-1][2]).to eq this_month.end_of_month.to_date.iso8601
        end
      end
    end
  end
end
