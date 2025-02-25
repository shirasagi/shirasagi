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

    # 2024/10/5 8:30 - 17:15 承認済み
    let(:overtime_holiday_file1) do
      file = create(:gws_affair2_overtime_holiday_file,
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
      file.reload
      file
    end

    # 2024/10/6 8:30 - 17:15 結果入力済み
    let(:overtime_holiday_file2) do
      file = create(:gws_affair2_overtime_holiday_file,
        cur_user: user1,
        in_date: "2024/10/6",
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
      file.reload

      record = file.record
      record.in_start_hour = 8
      record.in_start_minute = 30
      record.in_close_hour = 17
      record.in_close_minute = 15
      record.in_break_start_hour = 12
      record.in_break_start_minute = 0
      record.in_break_close_hour = 13
      record.in_break_close_minute = 0
      record.entered_at = Time.zone.now
      record.save!
      file.reload
      file
    end

    context "regular user" do
      let(:user) { affair2.users.u3 }

      it "#index" do
        visit gws_affair2_attendance_main_path site

        overtime_holiday_file1
        overtime_holiday_file2

        visit gws_affair2_book_form_main_path(site, "holiday_overtime")
        within ".sheet table" do
          within "tr.column0" do
            expect(all("td")[0]).to have_text("5日")
            expect(all("td")[0]).to have_text("土曜日")
          end
          within "tr.column1" do
            expect(all("td")[0]).to have_text("6日")
            expect(all("td")[0]).to have_text("日曜日")
          end
        end
      end
    end
  end
end
