require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:user1) { create(:gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids) }
  let!(:user2) { create(:gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids) }
  let!(:item) do
    create(:gws_schedule_plan, member_ids: [ user.id, user1.id, user2.id ], attendance_check_state: "enabled")
  end
  let(:user_comment) { unique_id }
  let(:user_comment2) { unique_id }

  context "attendance crud" do
    it do
      login_user user, to: gws_schedule_plan_path(site: site, id: item)

      within "#addon-gws-agents-addons-schedule-attendance" do
        wait_for_cbox_opened do
          first("span.attendances[data-member-id='#{user.id}'] input#item_attendances_#{user.id}_state_attendance").click
        end
      end

      within_cbox do
        within "#ajax-box #item-form" do
          fill_in "comment[text]", with: user_comment
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-schedule-comments" do
        expect(page).to have_content(user_comment)
      end
      within "#addon-gws-agents-addons-schedule-attendance" do
        expect(page).to have_css("input[name='item[attendances][#{user.id}][state]'][checked=checked][value='attendance']")
      end

      item.reload
      expect(item.comments.count).to eq 1
      item.comments.first.tap do |comment|
        expect(comment.user_id).to eq user.id
        expect(comment.text).to eq user_comment
      end
    end
  end

  context "facility manager attendance" do
    let!(:facility) { create(:gws_facility_item, cur_user: user) }
    let!(:plan) do
      create(:gws_schedule_plan,
        cur_user: user,
        member_ids: [user.id],
        facility_ids: [facility.id],
        attendance_check_state: "enabled"
      )
    end

    it "handles absence display correctly" do
      login_user user
      visit gws_schedule_plan_path(site: site, id: plan)

      # 欠席に設定
      within "#addon-gws-agents-addons-schedule-attendance" do
        wait_for_cbox_opened do
          first("span.attendances[data-member-id='#{user.id}'] input[value='absence']").click
        end
      end

      within_cbox do
        within "#ajax-box #item-form" do
          fill_in "comment[text]", with: "欠席します"
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      # カレンダー画面に移動
      visit gws_schedule_plans_path(site: site)

      # 不参加にした予定が非表示であることを確認
      expect(page).to have_css(".fc-event.fc-event-user-attendance-absence.hide")
      # 他の予定は表示されていることを確認
      expect(page).to have_css(".fc-event:not(.fc-event-user-attendance-absence)")

      # 欠席表示ボタンをオンにする
      find(".fc-withAbsence-button").click

      # 不参加にした予定が表示されていることを確認
      expect(page).to have_css(".fc-event.fc-event-user-attendance-absence:not(.hide)")
      # 他の予定も引き続き表示されていることを確認
      expect(page).to have_css(".fc-event:not(.fc-event-user-attendance-absence)")

      # 欠席表示ボタンをオフにする
      find(".fc-withAbsence-button").click

      # 不参加にした予定が再び非表示になったことを確認
      expect(page).to have_css(".fc-event.fc-event-user-attendance-absence.hide")
      # 他の予定は引き続き表示されていることを確認
      expect(page).to have_css(".fc-event:not(.fc-event-user-attendance-absence)")
    end
  end

  context "comment crud" do
    it do
      login_user user, to: gws_schedule_plan_path(site: site, id: item)

      #
      # Create
      #
      within "#addon-gws-agents-addons-schedule-comments" do
        within "#comment-form" do
          fill_in "item[text]", with: user_comment
          click_on I18n.t("gws/schedule.buttons.comment")
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-schedule-comments" do
        expect(page).to have_content(user_comment)
      end

      item.reload
      expect(item.comments.count).to eq 1
      comment = item.comments.first
      expect(comment.user_id).to eq user.id
      expect(comment.text).to eq user_comment

      #
      # Update
      #
      within "#addon-gws-agents-addons-schedule-comments" do
        within "#comment-#{comment.id}" do
          click_on I18n.t("ss.buttons.edit")
        end
      end
      within "form#item-form" do
        fill_in "item[text]", with: user_comment2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      within "#addon-gws-agents-addons-schedule-comments" do
        expect(page).to have_content(user_comment2)
      end

      item.reload
      expect(item.comments.count).to eq 1
      comment = item.comments.first
      expect(comment.user_id).to eq user.id
      expect(comment.text).to eq user_comment2

      #
      # Delete
      #
      within "#addon-gws-agents-addons-schedule-comments" do
        within "#comment-#{comment.id}" do
          click_on I18n.t("ss.buttons.delete")
        end
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      item.reload
      expect(item.comments.count).to eq 0
    end
  end
end
