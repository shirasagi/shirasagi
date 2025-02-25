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

    # 打刻無し
    context "case1" do
      # 1/6 終日 未承認
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_close_date: "2025/1/6",
          allday: "allday",
          leave_type: "sick1",
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

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_no_link(leave_file.label(:leave_type))
              end
            end
          end
        end
      end
    end

    # 打刻無し
    context "case2" do
      # 1/6 終日 承認済み
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_close_date: "2025/1/6",
          allday: "allday",
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_link(leave_file.label(:leave_type))
                wait_for_cbox_opened do
                  click_on leave_file.label(:leave_type)
                end
              end
            end
          end
          within_cbox do
            expect(page).to have_text(leave_file.name)
          end
        end
      end
    end

    # 8:30 - 17:15 60m
    context "case3" do
      let(:enter_hour) { "#{8}#{I18n.t("datetime.prompts.hour")}" }
      let(:enter_minute) { "#{30}#{I18n.t("datetime.prompts.minute")}" }

      let(:leave_hour) { "#{17}#{I18n.t("datetime.prompts.hour")}" }
      let(:leave_minute) { "#{15}#{I18n.t("datetime.prompts.minute")}" }

      # 1/6 10:00 - 12:00 時間給 承認済み
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_start_hour: "10",
          in_start_minute: "0",
          in_close_hour: "12",
          in_close_minute: "0",
          allday: nil,
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_link(leave_file.label(:leave_type))
              end
            end
          end

          # 2025/1/6 workday
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
              expect(page).to have_css(".work_time", text: "5:45")
              expect(page).to have_css(".over_break_time", text: "0:00")
              expect(page).to have_link(leave_file.label(:leave_type))
            end
          end
        end
      end
    end

    # 12:00 - 17:15 60m
    context "case4" do
      let(:enter_hour) { "#{12}#{I18n.t("datetime.prompts.hour")}" }
      let(:enter_minute) { "#{0}#{I18n.t("datetime.prompts.minute")}" }

      let(:leave_hour) { "#{17}#{I18n.t("datetime.prompts.hour")}" }
      let(:leave_minute) { "#{15}#{I18n.t("datetime.prompts.minute")}" }

      # 1/6 10:00 - 12:00 時間給 承認済み
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_start_hour: "10",
          in_start_minute: "0",
          in_close_hour: "12",
          in_close_minute: "0",
          allday: nil,
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_link(leave_file.label(:leave_type))
              end
            end
          end

          # 2025/1/6 workday
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
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "5:15")
              expect(page).to have_css(".over_break_time", text: "0:00")
              expect(page).to have_link(leave_file.label(:leave_type))
            end
          end
        end
      end
    end

    # 8:30 - 17:15 60m
    context "case5" do
      let(:enter_hour) { "#{8}#{I18n.t("datetime.prompts.hour")}" }
      let(:enter_minute) { "#{30}#{I18n.t("datetime.prompts.minute")}" }

      let(:leave_hour) { "#{17}#{I18n.t("datetime.prompts.hour")}" }
      let(:leave_minute) { "#{15}#{I18n.t("datetime.prompts.minute")}" }

      # 1/6 7:00 - 10:00 時間給 承認済み
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_start_hour: "7",
          in_start_minute: "0",
          in_close_hour: "10",
          in_close_minute: "0",
          allday: nil,
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_link(leave_file.label(:leave_type))
              end
            end
          end

          # 2025/1/6 workday
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
              expect(page).to have_css(".work_time", text: "6:15")
              expect(page).to have_css(".over_break_time", text: "0:00")
              expect(page).to have_link(leave_file.label(:leave_type))
            end
          end
        end
      end
    end

    # 9:30 - 17:15 60m
    context "case5" do
      let(:enter_hour) { "#{9}#{I18n.t("datetime.prompts.hour")}" }
      let(:enter_minute) { "#{30}#{I18n.t("datetime.prompts.minute")}" }

      let(:leave_hour) { "#{17}#{I18n.t("datetime.prompts.hour")}" }
      let(:leave_minute) { "#{15}#{I18n.t("datetime.prompts.minute")}" }

      # 1/6 7:00 - 10:00 時間給 承認済み
      let(:leave_file) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2025/1/6",
          in_start_hour: "7",
          in_start_minute: "0",
          in_close_hour: "10",
          in_close_minute: "0",
          allday: nil,
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it do
        Timecop.travel(month) do
          login_user(user1)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          leave_file

          visit gws_affair2_attendance_main_path(site: site)
          within ".attendance-box.monthly" do
            within ".day-6" do
              within ".leave_files" do
                expect(page).to have_link(leave_file.label(:leave_type))
              end
            end
          end

          # 2025/1/6 workday
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
              expect(page).to have_css(".work_time", text: "6:15")
              expect(page).to have_css(".over_break_time", text: "0:00")
              expect(page).to have_link(leave_file.label(:leave_type))
            end
          end
        end
      end
    end
  end
end
