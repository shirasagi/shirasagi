require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:user1) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }
  let(:now) { Time.zone.now }
  let(:this_month) { now.beginning_of_month }
  let!(:user1_this_month_time_card) do
    create :gws_attendance_time_card, cur_site: site, cur_user: user1, date: this_month
  end

  before do
    site.attendance_break_time1_state = 'show'
    site.attendance_break_time2_state = 'show'
    site.attendance_break_time3_state = 'show'
    site.save!
  end

  before { login_user user }

  describe 'cell edit' do
    context "with not current date" do
      let(:record_date) { user1_this_month_time_card.date.change(day: now.day <= 15 ? rand(16..28) : rand(1..15)) }
      let(:record_time) { record_date.change(hour: rand(7..9), min: rand(0..59)) }
      let(:hour_label) { I18n.t('gws/attendance.hour', count: record_time.hour) }
      let(:min_label) { I18n.t('gws/attendance.minute', count: record_time.min) }
      let(:reason) { "reason-#{unique_id}" }

      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        month = I18n.l(this_month.to_date, format: :attendance_year_month)
        title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user1.name, month: month)
        click_on title

        first(".time-card .day-#{record_date.day} .enter").click
        within ".cell-toolbar" do
          wait_cbox_open do
            click_on I18n.t("ss.links.edit")
          end
        end

        wait_for_cbox do
          within ".cell-edit" do
            select hour_label, from: "cell[in_hour]"
            select min_label, from: "cell[in_minute]"
            fill_in "cell[in_reason]", with: reason

            click_on I18n.t("ss.buttons.save")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")

        user1_this_month_time_card.reload
        record = user1_this_month_time_card.records.where(date: record_date).first
        expect(record.enter).to eq record_time
      end
    end

    context "with current date" do
      let(:record_date) { user1_this_month_time_card.date.change(day: now.day) }
      let(:record_time) { record_date.change(hour: rand(7..9), min: rand(0..59)) }
      let(:hour_label) { I18n.t('gws/attendance.hour', count: record_time.hour) }
      let(:min_label) { I18n.t('gws/attendance.minute', count: record_time.min) }
      let(:reason) { "reason-#{unique_id}" }

      it do
        visit gws_attendance_main_path(site)
        within first(".mod-navi") do
          click_on I18n.t('modules.gws/attendance/management/time_card')
        end

        month = I18n.l(this_month.to_date, format: :attendance_year_month)
        title = I18n.t('gws/attendance.formats.time_card_full_name', user_name: user1.name, month: month)
        click_on title

        first(".time-card .current .enter").click
        within ".cell-toolbar" do
          wait_cbox_open do
            click_on I18n.t("ss.links.edit")
          end
        end

        wait_for_cbox do
          within ".cell-edit" do
            select hour_label, from: "cell[in_hour]"
            select min_label, from: "cell[in_minute]"
            fill_in "cell[in_reason]", with: reason

            click_on I18n.t("ss.buttons.save")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")

        user1_this_month_time_card.reload
        record = user1_this_month_time_card.records.where(date: record_date).first
        expect(record.enter).to eq record_time
      end
    end
  end
end
