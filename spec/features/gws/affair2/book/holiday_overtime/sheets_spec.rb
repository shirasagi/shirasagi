require 'spec_helper'

describe "gws_affair2_book_holiday_overtime", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }
  let!(:time) { Time.zone.parse("2024/10/1 8:00") }

  around do |example|
    travel_to(time) { example.run }
  end

  context "basic" do
    let(:user1) { affair2.users.u3 }
    let(:user2) { affair2.users.u2 }
    let(:group) { affair2.groups.g1_1_1 }

    before { login_user(user) }

    context "regular user" do
      let(:user) { affair2.users.u3 }

      it "#index" do
        visit gws_affair2_attendance_main_path site

        32.times do
          # 2024/10/7 17:15 - 18:15 承認済み
          create(:gws_affair2_overtime_holiday_file,
            cur_user: user1,
            in_date: "2024/10/5",
            in_start_hour: 8,
            in_start_minute: 30,
            in_close_hour: 17,
            in_close_minute: 15,
            expense: "settle",
            state: "approve",
            workflow_user: user1,
            workflow_state: "approve",
            workflow_required_counts: [false],
            workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
        end

        visit gws_affair2_book_form_main_path(site, "holiday_overtime")
        within ".sheets" do
          expect(page).to have_selector(".sheet", count: 3)
        end
        within ".nav-group" do
          click_on I18n.t("ss.buttons.print")
        end
        within "#main" do
          expect(page).to have_selector(".sheet", count: 3)
        end
      end
    end
  end
end
