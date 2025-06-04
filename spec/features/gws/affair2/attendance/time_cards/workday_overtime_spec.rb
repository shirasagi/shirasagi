require 'spec_helper'

describe "gws_affair2_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let(:month) do
    month = Time.zone.parse("2025/1/1")
    month = month.advance(minutes: site.affair2_time_changed_minute)
    month
  end
  let(:time_card_title) do
    month = Time.zone.parse("2025/1/1").to_date
    I18n.t('gws/attendance.formats.time_card_name', month: I18n.l(month, format: :attendance_year_month))
  end

  # duty 8:30 - 17:15
  context "regular user" do
    let(:user1) { affair2.users.u3 }
    let(:user2) { affair2.users.u2 }

    # 8:30 - 17:15 60m
    context "case1" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 8) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 30) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 17) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 15) }

      # 17:15 - 18:15 未承認
      let(:overtime_workday_file) do
        create(:gws_affair2_overtime_workday_file,
          cur_user: user1,
          in_date: "2025/1/6",
          in_start_hour: 17,
          in_start_minute: 15,
          in_close_hour: 18,
          in_close_minute: 15,
          state: "request",
          workflow_state: "request",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "request", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          overtime_workday_file

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-6" do
              first(".time.enter").click
            end
            within ".cell-toolbar" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.links.edit")
              end
            end
          end
          within_cbox do
            select enter_hour, from: "item_hour"
            select enter_minute, from: "item_minute"
            fill_in "item[reason]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          ## leave
          within ".attendance-box.monthly" do
            within ".day-6" do
              first(".time.leave").click
            end
            within ".cell-toolbar" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.links.edit")
              end
            end
          end
          within_cbox do
            select leave_hour, from: "item_hour"
            select leave_minute, from: "item_minute"
            fill_in "item[reason]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          within ".attendance-box.monthly" do
            within ".day-6" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end
  end

  # duty 8:30 - 17:15
  context "regular user" do
    let(:user1) { affair2.users.u3 }
    let(:user2) { affair2.users.u2 }

    # 8:30 - 17:15 60m
    context "case1" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 8) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 30) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 17) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 15) }

      # 17:15 - 18:15 承認済み
      let(:overtime_workday_file) do
        create(:gws_affair2_overtime_workday_file,
          cur_user: user1,
          in_date: "2025/1/6",
          in_start_hour: 17,
          in_start_minute: 15,
          in_close_hour: 18,
          in_close_minute: 15,
          state: "approve",
          workflow_user: user1,
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end
      let(:overtime_record) { overtime_workday_file.record }

      it do
        Timecop.travel(month) do
          login_user(user1)

          # create time_card
          visit gws_affair2_attendance_main_path(site: site)

          # create workday_file
          overtime_workday_file.reload
          expect(overtime_record).to be_present
          expect(overtime_record.state).to eq "order"
          expect(overtime_record.entered?).to be_falsey
          expect(overtime_record.confirmed?).to be_falsey

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              expect(page).to have_css(".break_minutes", text: "--:--")
              expect(page).to have_css(".work_time", text: "--:--")
              within ".over_time" do
                expect(page).to have_text("--:--")
                expect(page).to have_link "結果を入力[命令]"
              end
              expect(page).to have_css(".over_break_time", text: "--:--")
            end
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-6" do
              first(".time.enter").click
            end
            within ".cell-toolbar" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.links.edit")
              end
            end
          end
          within_cbox do
            select enter_hour, from: "item_hour"
            select enter_minute, from: "item_minute"
            fill_in "item[reason]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          ## leave
          within ".attendance-box.monthly" do
            within ".day-6" do
              first(".time.leave").click
            end
            within ".cell-toolbar" do
              wait_for_cbox_opened do
                click_on I18n.t("ss.links.edit")
              end
            end
          end
          within_cbox do
            select leave_hour, from: "item_hour"
            select leave_minute, from: "item_minute"
            fill_in "item[reason]", with: unique_id
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          within ".attendance-box.monthly" do
            within ".day-6" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              within ".over_time" do
                expect(page).to have_text("0:00")
                expect(page).to have_link "結果を入力[命令]"
              end
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end

          # 結果を入力
          within ".attendance-box.monthly" do
            within ".day-6" do
              wait_for_cbox_opened do
                click_on "結果を入力[命令]"
              end
            end
          end
          within_cbox do
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          within ".attendance-box.monthly" do
            within ".day-6" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              within ".over_time" do
                expect(page).to have_text("0:00")
                expect(page).to have_link "1:00[命令]"
                expect(page).to have_css(".overtime-diff", text: "-1:00")
              end
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end

          # 確認済みにする
          login_user(user2)
          visit gws_affair2_overtime_workday_file_path(site, overtime_workday_file)
          within "#addon-gws-agents-addons-affair2-overtime_record" do
            expect(page).to have_text("承認者は結果を確認済みにしてください。")
            page.accept_alert do
              click_on "確認済みにする"
            end
          end
          within "#addon-gws-agents-addons-affair2-overtime_record" do
            expect(page).to have_text("結果は確認済みです。")
          end

          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            within ".day-6" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              within ".over_time" do
                expect(page).to have_text("0:00")
                expect(page).to have_text("1:00[確認]")
                expect(page).to have_css(".overtime-diff", text: "-1:00")
              end
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end
  end
end
