require 'spec_helper'

describe "gws_affair2_book_time_cards", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }
  let!(:time) { Time.zone.parse("2024/10/1 8:00") }

  around do |example|
    travel_to(time) { example.run }
  end

  context "basic" do
    before { login_user(user1) }

    context "regular user" do
      let(:user1) { affair2.users.u3 }
      let(:user2) { affair2.users.u2 }
      let(:group) { affair2.groups.g1_1_1 }

      # 2024/10/7 終日 paid 承認済み
      let(:leave_file1) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2024/10/7",
          in_close_date: "2024/10/7",
          allday: "allday",
          leave_type: "paid",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      # 2024/10/8 終日 sick1 承認済み
      let(:leave_file2) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2024/10/8",
          in_close_date: "2024/10/8",
          allday: "allday",
          leave_type: "sick1",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      # 2024/10/9 終日 sick2 承認済み
      let(:leave_file3) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2024/10/9",
          in_close_date: "2024/10/9",
          allday: "allday",
          leave_type: "sick2",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      # 2024/10/10 終日 nursing_care 承認済み
      let(:leave_file4) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2024/10/10",
          in_close_date: "2024/10/10",
          allday: "allday",
          leave_type: "nursing_care",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      # 2024/10/11 終日 special 承認済み
      let(:leave_file5) do
        create(:gws_affair2_leave_file,
          cur_user: user1,
          in_start_date: "2024/10/11",
          in_close_date: "2024/10/11",
          allday: "allday",
          leave_type: "special",
          state: "approve",
          workflow_state: "approve",
          workflow_required_counts: [false],
          workflow_approvers: [{ level: 1, user_id: user2.id, editable: "", state: "approve", comment: "" }])
      end

      it "#index" do
        visit gws_affair2_attendance_main_path site

        leave_file1
        leave_file2
        leave_file3
        leave_file4
        leave_file5

        visit gws_affair2_book_form_main_path(site, "time_cards")

        within ".attendance" do
          within "tbody" do
            expect(all(".leave.paid .count")[0]).to have_text("1日")
            expect(all(".leave.sick .count")[0]).to have_text("2日")
            expect(all(".leave.special .count")[0]).to have_text("1日")
            expect(all(".leave.nursing_care .count")[0]).to have_text("1日")
          end
        end
      end
    end
  end
end
