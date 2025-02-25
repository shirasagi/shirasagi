require 'spec_helper'

describe "gws_affair2_book_workday_overtime", type: :feature, dbscope: :example, js: true do
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

    # 2024/10/7 17:15 - 18:15 承認済み
    let(:overtime_workday_file1) do
      file = create(:gws_affair2_overtime_workday_file,
        cur_user: user1,
        in_date: "2024/10/7",
        in_start_hour: 17,
        in_start_minute: 15,
        in_close_hour: 18,
        in_close_minute: 15,
        state: "approve",
        workflow_user: user1,
        workflow_state: "approve",
        workflow_required_counts: [false],
        workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      file.reload
      file
    end

    # 2024/10/8 17:15 - 20:00 承認済み
    let(:overtime_workday_file2) do
      file = create(:gws_affair2_overtime_workday_file,
        cur_user: user1,
        in_date: "2024/10/8",
        in_start_hour: 17,
        in_start_minute: 15,
        in_close_hour: 20,
        in_close_minute: 0,
        state: "approve",
        workflow_user: user1,
        workflow_state: "approve",
        workflow_required_counts: [false],
        workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      file.reload
      file
    end

    # 2024/10/9 17:15 - 18:15 結果入力済み
    let(:overtime_workday_file3) do
      file = create(:gws_affair2_overtime_workday_file,
        cur_user: user1,
        in_date: "2024/10/9",
        in_start_hour: 17,
        in_start_minute: 15,
        in_close_hour: 18,
        in_close_minute: 15,
        state: "approve",
        workflow_user: user1,
        workflow_state: "approve",
        workflow_required_counts: [false],
        workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      file.reload

      record = file.record
      record.in_start_hour = 17
      record.in_start_minute = 15
      record.in_close_hour = 18
      record.in_close_minute = 15
      record.in_break_start_hour = 17
      record.in_break_start_minute = 15
      record.in_break_close_hour = 17
      record.in_break_close_minute = 15
      record.entered_at = Time.zone.now
      record.save!
      file.reload
      file
    end

    # 2024/10/10 17:15 - 20:00 結果入力済み
    let(:overtime_workday_file4) do
      file = create(:gws_affair2_overtime_workday_file,
        cur_user: user1,
        in_date: "2024/10/10",
        in_start_hour: 17,
        in_start_minute: 15,
        in_close_hour: 20,
        in_close_minute: 0,
        state: "approve",
        workflow_user: user1,
        workflow_state: "approve",
        workflow_required_counts: [false],
        workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      file.reload

      record = file.record
      record.in_start_hour = 17
      record.in_start_minute = 15
      record.in_close_hour = 20
      record.in_close_minute = 0
      record.in_break_start_hour = 17
      record.in_break_start_minute = 15
      record.in_break_close_hour = 17
      record.in_break_close_minute = 45
      record.entered_at = Time.zone.now
      record.save!
      file.reload
      file
    end

    context "regular user" do
      let(:user) { affair2.users.u3 }

      it "#index" do
        visit gws_affair2_attendance_main_path site

        overtime_workday_file1
        overtime_workday_file2
        overtime_workday_file3
        overtime_workday_file4

        visit gws_affair2_book_form_main_path(site, "workday_overtime")
        within ".sheet table" do
          within "tr.column0" do
            expect(all("td")[0]).to have_text("7日")
            expect(all("td")[0]).to have_text("月曜日")
          end
          within "tr.column1" do
            expect(all("td")[0]).to have_text("8日")
            expect(all("td")[0]).to have_text("火曜日")
          end
          within "tr.column2" do
            expect(all("td")[0]).to have_text("9日")
            expect(all("td")[0]).to have_text("水曜日")
          end
          within "tr.column3" do
            expect(all("td")[0]).to have_text("10日")
            expect(all("td")[0]).to have_text("木曜日")
          end
        end
      end
    end
  end
end
