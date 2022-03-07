require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  context "approval" do
    let(:site) { gws_site }
    let(:member_user) do
      create :gws_user, group_ids: [gws_site.id],
       notice_schedule_user_setting: "notify",
       send_notice_mail_addresses: "ss@example.jp"
    end
    let(:item) { create :gws_schedule_plan, member_ids: [gws_user.id, member_user.id] }
    let(:show_path) { gws_schedule_plan_path site, item }
    let(:edit_path) { edit_gws_schedule_plan_path site, item }
    let(:comment) { "comment-#{unique_id}" }

    before { login_gws_user }

    it "#edit plan (request)" do
      item.update(approval_member_ids: [member_user.id])
      visit edit_path

      within ".gws-addon-schedule-approval" do
        wait_cbox_open do
          click_on I18n.t('ss.apis.users.index')
        end
      end
      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        wait_cbox_close do
          click_on gws_user.name
        end
      end
      within "form#item-form" do
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show plan (approve)" do
      item.update(approval_member_ids: [gws_user.id])
      visit show_path

      within "#addon-gws-agents-addons-schedule-approval" do
        wait_cbox_open do
          choose "item_approvals_#{gws_user.id}_state_approve"
        end
      end
      wait_for_cbox do
        fill_in "comment[text]", with: comment
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-gws-agents-addons-schedule-comments" do
        expect(page).to have_css(".list-item", text: comment)
      end
    end

    it "#show plan (deny)" do
      item.update(approval_member_ids: [gws_user.id])
      visit show_path

      within "#addon-gws-agents-addons-schedule-approval" do
        wait_cbox_open do
          choose "item_approvals_#{gws_user.id}_state_deny"
        end
      end
      wait_for_cbox do
        fill_in "comment[text]", with: comment
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      within "#addon-gws-agents-addons-schedule-comments" do
        expect(page).to have_css(".list-item", text: comment)
      end
    end
  end
end
