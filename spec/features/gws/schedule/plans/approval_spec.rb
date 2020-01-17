require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "approval", js: true do
    let(:site) { gws_site }
    let(:member_user) do
      create :gws_user, group_ids: [gws_site.id],
       notice_schedule_user_setting: "notify",
       send_notice_mail_addresses: "ss@example.jp"
    end
    let(:item) { create :gws_schedule_plan, member_ids: [gws_user.id, member_user.id] }
    let(:show_path) { gws_schedule_plan_path site, item }
    let(:edit_path) { edit_gws_schedule_plan_path site, item }

    before { login_gws_user }

    it "#edit plan (request)" do
      item.update(approval_member_ids: [member_user.id])
      visit edit_path

      within ".gws-addon-schedule-approval" do
        click_on I18n.t('ss.apis.users.index')
      end
      wait_for_cbox do
        expect(page).to have_content(gws_user.name)
        click_on gws_user.name
      end
      within "form#item-form" do
        click_button I18n.t("ss.buttons.save")
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show plan (approve)" do
      item.update(approval_member_ids: [gws_user.id])
      visit show_path

      within "#addon-gws-agents-addons-schedule-approval" do
        choose "item_approvals_#{gws_user.id}_state_approve"
      end
      wait_for_cbox do
        fill_in "comment[text]", with: "comment"
        click_button I18n.t("ss.buttons.save")
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show plan (deny)" do
      item.update(approval_member_ids: [gws_user.id])
      visit show_path

      within "#addon-gws-agents-addons-schedule-approval" do
        choose "item_approvals_#{gws_user.id}_state_deny"
      end
      wait_for_cbox do
        fill_in "comment[text]", with: "comment"
        click_button I18n.t("ss.buttons.save")
      end

      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end
  end
end
