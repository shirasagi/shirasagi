require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:member_user) do
    create :gws_user, group_ids: gws_user.group_ids,
     notice_schedule_user_setting: "notify",
     send_notice_mail_addresses: "#{unique_id}@example.jp"
  end
  let(:item) { create :gws_schedule_plan, member_ids: [gws_user.id, member_user.id] }
  let(:plan_name) { "name-#{unique_id}" }
  let(:notice_path) do
    url_helper = Rails.application.routes.url_helpers
    url_helper.gws_schedule_plan_path(site: gws_site, id: item.id)
  end
  let(:mail_url) do
    url_helper = Rails.application.routes.url_helpers
    notice = SS::Notification.first
    url_helper.gws_memo_notice_url(protocol: site.canonical_scheme, host: site.canonical_domain, site: site, id: notice)
  end

  let(:edit_path) { edit_gws_schedule_plan_path site, item }
  let(:delete_path) { soft_delete_gws_schedule_plan_path site, item }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    login_gws_user

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "#create plan" do
    let(:notice_path) do
      url_helper = Rails.application.routes.url_helpers
      url_helper.gws_schedule_plan_path(site: site, id: Gws::Schedule::Plan.first)
    end

    def create_plan(notify_state)
      visit new_gws_schedule_plan_path(site: site)

      within "form#item-form" do
        fill_in "item[name]", with: plan_name
        select I18n.t("ss.options.state.#{notify_state}"), from: "item_notify_state" rescue nil
        within "#addon-gws-agents-addons-member" do
          click_on I18n.t("ss.apis.users.index")
        end
      end
      wait_for_cbox do
        click_on member_user.long_name
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          expect(page).to have_css(".ajax-selected", text: member_user.name)
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    context "with notify_state disabled" do
      it do
        create_plan("disabled")

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled" do
      it do
        create_plan("enabled")

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq notice_path
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled and email enabled" do
      before do
        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!
      end

      it do
        create_plan("enabled")

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(notice.url).to eq notice_path

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq member_user.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(mail.decoded.to_s).to include(mail.subject)
        expect(mail.decoded.to_s).to include(mail_url)
      end
    end

    context "with site's notice_schedule_state is set to force_silence" do
      before do
        site.notice_schedule_state = "force_silence"
        site.save!

        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!
      end

      it do
        create_plan("enabled")

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end
  end

  context "#edit plan" do
    def edit_plan
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: plan_name
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    context "with notify_state disabled" do
      before do
        item.notify_state = "disabled"
        item.save!
      end

      it do
        edit_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled" do
      before do
        item.notify_state = "enabled"
        item.save!
      end

      it do
        edit_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq notice_path
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled and email enabled" do
      before do
        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.save!
      end

      it do
        edit_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(notice.url).to eq notice_path

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq member_user.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/schedule/plan.subject", name: plan_name)
        expect(mail.decoded.to_s).to include(mail.subject)
        expect(mail.decoded.to_s).to include(mail_url)
      end
    end

    context "with notify_state enabled and email enabled but site's notice_schedule_state is set to force_silence" do
      before do
        site.notice_schedule_state = "force_silence"
        site.save!

        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.save!
      end

      it do
        edit_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end
  end

  context "#soft_delete plan" do
    def delete_plan
      visit delete_path
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      click_on I18n.t("ss.links.trash")
      within ".list-items" do
        expect(page).to have_content(item.name)
      end
    end

    context "with notify_state disabled" do
      before do
        item.notify_state = "disabled"
        item.save!
      end

      it do
        delete_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled" do
      before do
        item.notify_state = "enabled"
        item.save!
      end

      it do
        delete_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan/destroy.subject", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to be_blank
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled and email enabled" do
      before do
        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.save!
      end

      it do
        delete_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan/destroy.subject", name: item.name)
        expect(notice.url).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq member_user.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/schedule/plan/destroy.subject", name: item.name)
        expect(mail.decoded.to_s).to include(item.name)
        expect(mail.decoded.to_s).to include(mail_url)
      end
    end

    context "with notify_state enabled and email enabled but site's notice_schedule_state is set to force_silence" do
      before do
        site.notice_schedule_state = "force_silence"
        site.save!

        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.save!
      end

      it do
        delete_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end
  end

  context "#hard_delete plan" do
    def purge_plan
      visit gws_schedule_main_path(site: site)
      click_on I18n.t("ss.links.trash")
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    context "with notify_state disabled" do
      before do
        item.notify_state = "disabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        purge_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled" do
      before do
        item.notify_state = "enabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        purge_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled and email enabled" do
      before do
        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        purge_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end
  end

  context "#undo_delete plan" do
    def undo_delete_plan
      visit gws_schedule_main_path(site: site)
      click_on I18n.t("ss.links.trash")
      click_on item.name
      click_on I18n.t("ss.links.restore")
      within "form" do
        click_button I18n.t("ss.buttons.restore")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.restored'))
    end

    context "with notify_state disabled" do
      before do
        item.notify_state = "disabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        undo_delete_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled" do
      before do
        item.notify_state = "enabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        undo_delete_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan/undo_delete.subject", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq notice_path
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end

    context "with notify_state enabled and email enabled" do
      before do
        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        undo_delete_plan

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.member_ids).to eq [ member_user.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/schedule/plan/undo_delete.subject", name: item.name)
        expect(notice.url).to eq notice_path

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq member_user.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/schedule/plan/undo_delete.subject", name: item.name)
        expect(mail.decoded.to_s).to include(item.name)
        expect(mail.decoded.to_s).to include(mail_url)
      end
    end

    context "with notify_state enabled and email enabled but site's notice_schedule_state is set to force_silence" do
      before do
        site.notice_schedule_state = "force_silence"
        site.save!

        member_user.notice_schedule_email_user_setting = "notify"
        member_user.save!

        item.notify_state = "enabled"
        item.deleted = Time.zone.now
        item.save!
      end

      it do
        undo_delete_plan

        notice = SS::Notification.first
        expect(notice).to be_blank

        mail = ActionMailer::Base.deliveries.first
        expect(mail).to be_blank
      end
    end
  end
end
