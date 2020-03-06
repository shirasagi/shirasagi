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
      login_user user
      visit gws_schedule_plan_path(site: site, id: item)

      within "#addon-gws-agents-addons-schedule-attendance" do
        first("span.attendances[data-member-id='#{user.id}'] input#item_attendances_#{user.id}_state_attendance").click
      end

      wait_for_cbox do
        within "#ajax-box #item-form" do
          fill_in "comment[text]", with: user_comment
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

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

  context "comment crud" do
    it do
      login_user user
      visit gws_schedule_plan_path(site: site, id: item)

      #
      # Create
      #
      within "#addon-gws-agents-addons-schedule-comments" do
        within "#comment-form" do
          fill_in "item[text]", with: user_comment
          click_on I18n.t("gws/schedule.buttons.comment")
        end
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

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
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

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
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      item.reload
      expect(item.comments.count).to eq 0
    end
  end
end
