require 'spec_helper'

describe "gws_affair2_overtime_workday_files", type: :feature, dbscope: :example, js: true do
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
    visit new_gws_affair2_overtime_workday_file_path(site)

    within "form#item-form" do
      fill_in "item[name]", with: unique_id
      fill_in_datetime "item[in_date]", with: "2025/1/6"
      select "17", from: "item_in_start_hour"
      select "15", from: "item_in_start_minute"
      select "18", from: "item_in_close_hour"
      select "15", from: "item_in_close_minute"
      click_button I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t("ss.notice.saved")

    Gws::Affair2::Overtime::File.first
  end

  # 承認
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

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 0

        visit gws_affair2_overtime_workday_file_path(site, item)
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
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.request", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 申請を承認する
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          click_on I18n.t("workflow.buttons.approve")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.approve"))
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.approve", name: item.name)
        expect(notification.url).to eq item.private_show_path
      end
    end
  end

  # 差し戻し
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

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 0

        visit gws_affair2_overtime_workday_file_path(site, item)
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
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.request", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 申請を差し戻す
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment
          click_on I18n.t("workflow.buttons.remand")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.remand"))
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.remand", name: item.name)
        expect(notification.url).to eq item.private_show_path
      end
    end
  end

  # 回覧、コメント
  context "regular user" do
    let!(:user1) { affair2.users.u3 }
    let!(:group1) { affair2.groups.g1_1_1 }

    let!(:user2) { affair2.users.u2 }
    let!(:group2) { affair2.groups.g1_1 }

    let!(:user3) { affair2.users.u4 }
    let!(:group3) { affair2.groups.g1_1_1 }

    let(:workflow_comment) { unique_id }
    let(:circulation_comment) { unique_id }

    it do
      Timecop.travel(month) do
        login_user(user1)

        create_time_card

        item = create_overtime_file

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 0
        expect(SS::Notification.member(user3).count).to eq 0

        visit gws_affair2_overtime_workday_file_path(site, item)
        expect(page).to have_css("#addon-basic", text: item.name)

        #
        # 回覧者を設定し申請する
        #
        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          wait_cbox_open { click_on I18n.t("workflow.search_circulations.index") }
        end
        wait_for_cbox do
          expect(page).to have_content(user3.long_name)
          find("tr[data-id=\"circulation1,#{user3.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow..search_circulations.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 1
        expect(SS::Notification.member(user3).count).to eq 0

        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.request", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 申請を承認する
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          click_on I18n.t("workflow.buttons.approve")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.approve"))
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.approve"))
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 1
        expect(SS::Notification.member(user3).count).to eq 1

        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.approve", name: item.name)
        expect(notification.url).to eq item.private_show_path

        notification = SS::Notification.member(user3).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.circular", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 回覧者がコメントをする
        #

        login_user(user3)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: circulation_comment
          click_on I18n.t("workflow.links.set_seen")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.approve"))
        end

        login_user(user1)
        visit gws_affair2_overtime_workday_file_path(site, item)
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(circulation_comment)
        end

        expect(SS::Notification.member(user1).count).to eq 2
        expect(SS::Notification.member(user2).count).to eq 1
        expect(SS::Notification.member(user3).count).to eq 1

        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.comment", name: item.name)
        expect(notification.url).to eq item.private_show_path
      end
    end
  end

  # 結果入力、結果確認（申請の詳細画面）
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

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 0

        visit gws_affair2_overtime_workday_file_path(site, item)
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
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.request", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 申請を承認する
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          click_on I18n.t("workflow.buttons.approve")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.approve"))
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.approve", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 結果を入力する
        #

        login_user(user1)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("結果を入力してください。")
          click_on "結果を入力"
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          click_on I18n.t("ss.buttons.save")
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("承認者は結果を確認済みにしてください。")
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 2
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.record_entered", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 再度結果を入力する
        #

        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("承認者は結果を確認済みにしてください。")
          click_on "結果を編集"
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          click_on I18n.t("ss.buttons.save")
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("承認者は結果を確認済みにしてください。")
        end
        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 2

        #
        # 結果を確認済みにする
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("承認者は結果を確認済みにしてください。")
          page.accept_alert do
            click_on "確認済みにする"
          end
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("結果は確認済みです。")
        end
        expect(SS::Notification.member(user1).count).to eq 2
        expect(SS::Notification.member(user2).count).to eq 2

        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.record_confirmed", name: item.name)
        expect(notification.url).to eq item.private_show_path
      end
    end
  end

  # 結果入力、結果確認（タイムカード）
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

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 0

        visit gws_affair2_overtime_workday_file_path(site, item)
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
          expect(page).to have_content(user2.long_name)
          find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        within "#addon-gws-agents-addons-affair2-approver" do
          expect(page).to have_text(I18n.t("workflow.state.request"))
        end

        expect(SS::Notification.member(user1).count).to eq 0
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.request", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 申請を承認する
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)

        within ".mod-workflow-approve" do
          click_on I18n.t("workflow.buttons.approve")
        end
        within "#addon-basic" do
          expect(page).to have_text(I18n.t("gws/affair2.options.state.approve"))
        end

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 1
        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.approve", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 結果を入力する
        #

        login_user(user1)
        visit gws_affair2_attendance_main_path(site)

        within ".day-6 .over_time" do
          expect(page).to have_link "結果を入力[命令]"
          wait_for_cbox_opened do
            click_on "結果を入力[命令]"
          end
        end
        within_cbox do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(SS::Notification.member(user1).count).to eq 1
        expect(SS::Notification.member(user2).count).to eq 2
        notification = SS::Notification.member(user2).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.record_entered", name: item.name)
        expect(notification.url).to eq item.private_show_path

        #
        # 結果を確認済みにする
        #

        login_user(user2)
        visit gws_affair2_overtime_workday_file_path(site, item)
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("承認者は結果を確認済みにしてください。")
          page.accept_alert do
            click_on "確認済みにする"
          end
        end
        within "#addon-gws-agents-addons-affair2-overtime_record" do
          expect(page).to have_text("結果は確認済みです。")
        end
        expect(SS::Notification.member(user1).count).to eq 2
        expect(SS::Notification.member(user2).count).to eq 2

        notification = SS::Notification.member(user1).first
        expect(notification.subject).to eq I18n.t("gws_notification.gws/affair2/overtime/workday_file.record_confirmed", name: item.name)
        expect(notification.url).to eq item.private_show_path
      end
    end
  end
end
