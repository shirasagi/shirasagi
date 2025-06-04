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
  context "regular user3" do
    let(:user) { affair2.users.u3 }

    # 8:30 - 17:15 60m
    context "case1" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 8) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 30) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 17) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 15) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 8:00 - 15:00 60m
    context "case2" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 8) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "5:30")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 8:00 - 22:00 60m
    context "case3" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 8) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 22) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:45")
              expect(page).to have_css(".over_time", text: "4:45")
              expect(page).to have_css(".over_break_time", text: "4:45")
            end
          end
        end
      end
    end

    # 15:00 - 15:00 0m
    context "case4" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 18:00 - 22:00 0m
    context "case5" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 18) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 22) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "4:00")
              expect(page).to have_css(".over_break_time", text: "4:00")
            end
          end
        end
      end
    end

    # 7:00 - 7:30 0m
    context "case6" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 30) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 15:00 - 26:00 0m
    context "case7" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 26) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "2:15")
              expect(page).to have_css(".over_time", text: "8:45")
              expect(page).to have_css(".over_break_time", text: "8:45")
            end
          end
        end
      end
    end
  end

  # duty 7:45 - 16:15
  context "regular user10" do
    let(:user) { affair2.users.u10 }

    # 7:45 - 16:15 60m
    context "case1" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 45) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 16) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 15) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:30")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 7:35 - 15:00 60m
    context "case2" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 35) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "6:15")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 7:00 - 22:00 60m
    context "case3" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 22) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "1:00")
              expect(page).to have_css(".work_time", text: "7:30")
              expect(page).to have_css(".over_time", text: "5:45")
              expect(page).to have_css(".over_break_time", text: "5:45")
            end
          end
        end
      end
    end

    # 15:00 - 15:00 0m
    context "case4" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 18:00 - 22:00 0m
    context "case5" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 18) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 22) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "4:00")
              expect(page).to have_css(".over_break_time", text: "4:00")
            end
          end
        end
      end
    end

    # 7:00 - 7:30 0m
    context "case6" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 7) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 30) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "0:00")
              expect(page).to have_css(".over_time", text: "0:00")
              expect(page).to have_css(".over_break_time", text: "0:00")
            end
          end
        end
      end
    end

    # 15:00 - 26:00 0m
    context "case7" do
      let(:enter_hour) { I18n.t('gws/attendance.hour', count: 15) }
      let(:enter_minute) { I18n.t('gws/attendance.minute', count: 0) }

      let(:leave_hour) { I18n.t('gws/attendance.hour', count: 26) }
      let(:leave_minute) { I18n.t('gws/attendance.minute', count: 0) }

      it do
        Timecop.travel(month) do
          login_user(user)
          visit gws_affair2_attendance_main_path(site: site)

          within ".attendance-box.monthly" do
            expect(page).to have_css(".attendance-box-title", text: time_card_title)
            expect(page).to have_css(".day-1.current")
          end

          # 2025/1/2 workday
          ## enter
          within ".attendance-box.monthly" do
            within ".day-2" do
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
            within ".day-2" do
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
            within ".day-2" do
              expect(page).to have_css(".break_minutes", text: "0:00")
              expect(page).to have_css(".work_time", text: "1:15")
              expect(page).to have_css(".over_time", text: "9:45")
              expect(page).to have_css(".over_break_time", text: "9:45")
            end
          end
        end
      end
    end
  end
end
