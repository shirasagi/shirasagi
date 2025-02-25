require 'spec_helper'

describe "gws_affair2_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let(:month) do
    month = Time.zone.parse("2025/1/1")
    month = month.advance(minutes: site.affair2_time_changed_minute)
    month
  end

  context "denied with no attendance setting" do
    let!(:user) { gws_user }

    before { login_gws_user }

    it "#index" do
      visit gws_affair2_attendance_main_path site
      expect(page).to have_text(I18n.t("gws/affair2.notice.no_attendance_setting", user: user.long_name))
    end
  end

  context "basic" do
    context "regular user" do
      let(:user) { affair2.users.u3 }

      let(:enter_hour) { "#{8}#{I18n.t("datetime.prompts.hour")}" }
      let(:enter_minute) { "#{30}#{I18n.t("datetime.prompts.minute")}" }
      let(:enter_reason) { unique_id }

      let(:leave_hour) { "#{17}#{I18n.t("datetime.prompts.hour")}" }
      let(:leave_minute) { "#{15}#{I18n.t("datetime.prompts.minute")}" }
      let(:leave_reason) { unique_id }

      let(:break_minutes) { "#{60}#{I18n.t("datetime.prompts.minute")}" }
      let(:memo) { unique_id }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_attendance_main_path site

        # punch
        ## enter
        within ".attendance-box.today" do
          within ".action .enter" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        ## leave
        within ".attendance-box.today" do
          within ".action .leave" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        # edit
        ## enter
        within ".attendance-box.today" do
          within ".action .enter" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
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
        within ".attendance-box.today" do
          within ".action .leave" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
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

        ## break-time
        within ".attendance-box.today" do
          within ".action .break-time" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end
        within_cbox do
          select break_minutes, from: "item_minutes"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ## memo
        within ".attendance-box.today" do
          within ".action .memo" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end
        within_cbox do
          fill_in "item[memo]", with: memo
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
    end

    context "restricted user" do
      let(:user) { affair2.users.u11 }

      let(:break_minutes) { "#{60}#{I18n.t("datetime.prompts.minute")}" }
      let(:memo) { unique_id }

      before { login_user(user) }

      it "#index" do
        visit gws_affair2_attendance_main_path site

        # punch
        ## enter
        within ".attendance-box.today" do
          within ".action .enter" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        ## leave
        within ".attendance-box.today" do
          within ".action .leave" do
            page.accept_alert do
              click_on I18n.t("gws/attendance.buttons.punch")
            end
          end
        end
        wait_for_notice I18n.t("gws/attendance.notice.punched")

        # edit
        ## enter
        within ".attendance-box.today" do
          within ".action .enter" do
            expect(page).to have_css("button[disabled=\"disabled\"]")
          end
        end

        ## leave
        within ".attendance-box.today" do
          within ".action .leave" do
            expect(page).to have_css("button[disabled=\"disabled\"]")
          end
        end

        ## break-time
        within ".attendance-box.today" do
          within ".action .break-time" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end
        within_cbox do
          select break_minutes, from: "item_minutes"
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        ## memo
        within ".attendance-box.today" do
          within ".action .memo" do
            wait_for_cbox_opened do
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end
        within_cbox do
          fill_in "item[memo]", with: memo
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
    end
  end
end
