require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:group1) { create(:gws_group, name: "#{gws_site.name}/#{unique_id}") }
  let!(:group2) { create(:gws_group, name: "#{gws_site.name}/#{unique_id}") }
  let!(:user0) do
    create(
      :gws_user, group_ids: [ gws_site.id ], gws_role_ids: gws_user.gws_role_ids,
      notice_report_user_setting: "notify", notice_report_email_user_setting: "notify",
      send_notice_mail_addresses: "#{unique_id}@example.jp"
    )
  end
  let!(:user1) do
    create(
      :gws_user, group_ids: [ group1.id ], gws_role_ids: gws_user.gws_role_ids,
      notice_report_user_setting: "notify", notice_report_email_user_setting: "notify",
      send_notice_mail_addresses: "#{unique_id}@example.jp"
    )
  end
  let!(:user2) do
    create(
      :gws_user, group_ids: [ group2.id ], gws_role_ids: gws_user.gws_role_ids,
      notice_report_user_setting: "notify", notice_report_email_user_setting: "notify",
      send_notice_mail_addresses: "#{unique_id}@example.jp"
    )
  end
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column1_1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "optional", input_type: "text")
  end

  subject! do
    create(
      :gws_report_file, cur_site: site, cur_user: user0, group_ids: user0.group_ids, user_ids: [ user0.id ],
      state: "closed", member_ids: [ user1.id ], readable_setting_range: "select", readable_member_ids: [ user2.id ]
    )
  end

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    ActionMailer::Base.deliveries.clear
  end

  context "publish and notification" do
    it do
      # publish
      login_user user0
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.closed')
      end
      click_on subject.name
      click_on I18n.t("gws/report.links.publish")
      within "form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('gws/report.notice.published'))

      subject.reload
      expect(subject.state).to eq "public"

      expect(SS::Notification.all.count).to eq 1
      notice = SS::Notification.all.first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1.id ]
      expect(notice.user_id).to eq user0.id
      expect(notice.subject).to eq "[#{Gws::Report::File.model_name.human}] 「#{subject.name}」が届きました。"
      expect(notice.text).to be_blank
      expect(notice.html).to be_blank
      expect(notice.format).to eq "text"
      expect(notice.seen).to be_blank
      expect(notice.state).to eq "public"
      expect(notice.send_date).to be_present
      expect(notice.url).to eq "/.g#{site.id}/report/files/inbox/#{subject.id}"
      expect(notice.reply_module).to be_blank
      expect(notice.reply_model).to be_blank
      expect(notice.reply_item_id).to be_blank

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq "[#{Gws::Report::File.model_name.human}] 「#{subject.name}」が届きました。"
        expect(mail.decoded.to_s).to include(mail.subject)
        notice_url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(notice_url)
      end

      # user1 is able to read in inbox
      login_user user1
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.inbox')
      end
      click_on subject.name
      within "#addon-basic" do
        expect(page).to have_content(subject.name)
      end

      # user2 is able to read in readable
      login_user user2
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.readable')
      end
      click_on subject.name
      within "#addon-basic" do
        expect(page).to have_content(subject.name)
      end

      # depublish
      login_user user0
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.sent')
      end
      click_on subject.name
      click_on I18n.t("gws/report.links.depublish")
      within "form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('gws/report.notice.depublished'))

      subject.reload
      expect(subject.state).to eq "closed"

      expect(SS::Notification.all.count).to eq 2
      notice = SS::Notification.all.order_by(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1.id ]
      expect(notice.user_id).to eq user0.id
      expect(notice.subject).to eq "[#{Gws::Report::File.model_name.human}] 「#{subject.name}」の送信が取り消されました。"
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

      expect(ActionMailer::Base.deliveries.length).to eq 2
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        expect(mail.decoded.to_s).to include(mail.subject)
        notice_url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(notice_url)
      end
    end
  end

  context "publish with site's notice_schedule_state is set to force_silence" do
    before do
      site.notice_report_state = "force_silence"
      site.save!
    end

    it do
      login_user user0
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.closed')
      end
      click_on subject.name
      click_on I18n.t("gws/report.links.publish")
      within "form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('gws/report.notice.published'))

      subject.reload
      expect(subject.state).to eq "public"

      expect(SS::Notification.all.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end

  context "deleting published file" do
    before do
      site.notice_report_state = "force_silence"
      site.save!

      subject.state = 'public'
      subject.save!
    end

    it do
      login_user user0
      visit gws_report_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('gws/report.options.file_state.sent')
      end
      click_on subject.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      subject.reload
      expect(subject.deleted).to be_present

      expect(SS::Notification.all.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end
end
