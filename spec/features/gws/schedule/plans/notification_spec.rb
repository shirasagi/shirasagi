require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "notification", js: true do
    let(:site) { gws_site }
    let(:member_user) do
      create :gws_user, group_ids: [gws_site.id],
       notice_schedule_user_setting: "notify",
       send_notice_mail_address: "ss@example.jp"
    end
    let(:item) { create :gws_schedule_plan, member_ids: [gws_user.id, member_user.id] }
    let(:plan_name) { "name" }
    let(:canonical_domain) { "ss.example.jp" }
    let(:notice_url) do
      url_helper = Rails.application.routes.url_helpers
      url_helper.gws_schedule_plan_path(site: gws_site, id: item.id)
    end

    let(:edit_path) { edit_gws_schedule_plan_path site, item }
    let(:delete_path) { soft_delete_gws_schedule_plan_path site, item }

    before { login_gws_user }
    before do
      s = gws_site
      s.canonical_domain = canonical_domain
      s.save!
    end
    before { ActionMailer::Base.deliveries.clear }
    after { ActionMailer::Base.deliveries.clear }

    it "#edit plan (notify_state disabled)" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: plan_name
        select I18n.t("ss.options.state.disabled"), from: "item_notify_state"
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      notice = SS::Notification.first
      expect(notice.nil?).to be true

      mail = ActionMailer::Base.deliveries.first
      expect(mail.blank?).to be true
    end

    it "#edit plan (notify_state enabled)" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: plan_name
        select I18n.t("ss.options.state.enabled"), from: "item_notify_state"
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      notice = SS::Notification.first
      expect(notice.url).to include(notice_url)

      mail = ActionMailer::Base.deliveries.first
      expect(mail.blank?).to be true
    end

    it "#edit plan (notify_state enabled and email enabled)" do
      u = member_user
      u.notice_schedule_email_user_setting = "notify"
      u.save!

      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: plan_name
        select I18n.t("ss.options.state.enabled"), from: "item_notify_state"
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      notice = SS::Notification.first
      expect(notice.url).to include(notice_url)

      mail = ActionMailer::Base.deliveries.first
      expect(mail.decoded.to_s).to include(plan_name)
      expect(mail.decoded.to_s).to include(canonical_domain)
    end
  end
end
