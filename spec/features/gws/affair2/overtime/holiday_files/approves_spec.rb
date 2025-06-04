require 'spec_helper'

describe "gws_affair2_overtime_holiday_files", type: :feature, dbscope: :example, js: true do
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

  def create_time_card
    visit gws_affair2_attendance_main_path(site)

    within ".attendance-box.monthly" do
      expect(page).to have_css(".attendance-box-title", text: time_card_title)
      expect(page).to have_css(".day-1.current")
    end
  end

  def create_overtime_file
    visit new_gws_affair2_overtime_holiday_file_path(site)

    within "form#item-form" do
      fill_in "item[name]", with: unique_id
      fill_in_datetime "item[in_date]", with: "2025/1/11"
      select "17", from: "item_in_start_hour"
      select "15", from: "item_in_start_minute"
      select "18", from: "item_in_close_hour"
      select "15", from: "item_in_close_minute"
      choose "item_expense_settle"
      click_button I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t("ss.notice.saved")
    Gws::Affair2::Overtime::HolidayFile.first
  end

  # 自身に承認申請（承認権限無し）
  context "basic" do
    let!(:user) { affair2.users.u3 }
    let(:workflow_comment) { unique_id }

    it do
      Timecop.travel(month) do
        login_user(user)

        create_time_card

        item = create_overtime_file

        visit gws_affair2_overtime_holiday_file_path(site, item)
        expect(page).to have_css("#addon-basic", text: item.name)

        #
        # 申請する
        #
        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          expect(page).to have_content(user.long_name)
          find("tr[data-id=\"1,#{user.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
        end

        # 自身は承認権限が無いのでアラート表示して終了
        page.accept_alert(/#{::Regexp.escape(I18n.t("errors.messages.not_approve", name: user.name))}/) do
          click_on I18n.t("workflow.buttons.request")
        end

        item.reload
        expect(item.workflow_state).to eq nil
      end
    end
  end

  # 上長に承認申請、承認（承認権限有り）
  context "regular user" do
    let!(:user1) { affair2.users.u3 }
    let!(:group1) { affair2.groups.g1_1_1 }

    let!(:user2) { affair2.users.u2 }
    let!(:group2) { affair2.groups.g1_1 }

    let(:workflow_comment) { unique_id }

    it do
      Timecop.travel(month) do
        login_user(user1)

        create_time_card

        item = create_overtime_file
        # 所有グループに上位グループが含まれる
        expect(item.user_ids).to match_array([user1.id])
        expect(item.group_ids).to match_array([group1.id, group2.id])

        visit gws_affair2_overtime_holiday_file_path(site, item)
        expect(page).to have_css("#addon-basic", text: item.name)

        #
        # 申請する
        #
        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          # 上長を選択する
          # 庶務事務の申請は上位グループを選択状態とする為、ダイアログが開いた直後、上長をクリックできる
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment

          # 所有グループに上位グループが含まれる為、上長は閲覧権限有り。承認可能。
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers[0][:level]).to eq 1
        expect(item.workflow_approvers[0][:user_id]).to eq user2.id
        expect(item.workflow_approvers[0][:editable]).to eq ''
        expect(item.workflow_approvers[0][:state]).to eq 'request'
        expect(item.workflow_approvers[0][:created]).to be_blank

        #
        # 申請を承認する
        #

        login_user(user2)
        visit gws_affair2_overtime_holiday_file_path(site, item)

        within ".mod-workflow-approve" do
          click_on I18n.t("workflow.buttons.approve")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.approve"))
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers[0][:level]).to eq 1
        expect(item.workflow_approvers[0][:user_id]).to eq user2.id
        expect(item.workflow_approvers[0][:editable]).to eq ''
        expect(item.workflow_approvers[0][:state]).to eq 'approve'
        expect(item.workflow_approvers[0][:created]).to be_present

        #
        # 承認されたので再申請はできない
        #

        login_user(user1)
        visit gws_affair2_overtime_holiday_file_path(site, item)
        expect(page).to have_no_css(".mod-workflow-request")
      end
    end
  end

  # 上長に承認申請、差し戻し（承認権限有り）
  context "regular user" do
    let!(:user1) { affair2.users.u3 }
    let!(:group1) { affair2.groups.g1_1_1 }

    let!(:user2) { affair2.users.u2 }
    let!(:group2) { affair2.groups.g1_1 }

    let(:workflow_comment) { unique_id }
    let(:remand_comment) { unique_id }

    it do
      Timecop.travel(month) do
        login_user(user1)

        create_time_card

        item = create_overtime_file
        # 所有グループに上位グループが含まれる
        expect(item.user_ids).to match_array([user1.id])
        expect(item.group_ids).to match_array([group1.id, group2.id])

        visit gws_affair2_overtime_holiday_file_path(site, item)
        expect(page).to have_css("#addon-basic", text: item.name)

        #
        # 申請する
        #
        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          # 上長を選択する
          # 庶務事務の申請は上位グループを選択状態とする為、ダイアログが開いた直後、上長をクリックできる
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment

          # 所有グループに上位グループが含まれる為、上長は閲覧権限有り。承認可能。
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers[0][:level]).to eq 1
        expect(item.workflow_approvers[0][:user_id]).to eq user2.id
        expect(item.workflow_approvers[0][:editable]).to eq ''
        expect(item.workflow_approvers[0][:state]).to eq 'request'
        expect(item.workflow_approvers[0][:created]).to be_blank

        #
        # 申請を差し戻す
        #

        login_user(user2)
        visit gws_affair2_overtime_holiday_file_path(site, item)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment
          click_on I18n.t("workflow.buttons.remand")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.remand"))
        end

        item.reload
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_state).to eq 'remand'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers[0][:level]).to eq 1
        expect(item.workflow_approvers[0][:user_id]).to eq user2.id
        expect(item.workflow_approvers[0][:editable]).to eq ''
        expect(item.workflow_approvers[0][:state]).to eq 'remand'
        expect(item.workflow_approvers[0][:created]).to be_present
        expect(item.workflow_approvers[0][:comment]).to eq remand_comment

        #
        # 再申請が可能
        #

        login_user(user1)
        visit gws_affair2_overtime_holiday_file_path(site, item)

        within ".mod-workflow-request" do
          select I18n.t("workflow.restart_workflow"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.restart_workflow")
        end
      end
    end
  end
end
