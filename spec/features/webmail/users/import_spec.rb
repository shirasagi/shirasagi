require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "download template" do
    let!(:user1) { create(:ss_user, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:ss_user, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:ss_user, id: 103, email: "#{unique_id}-3@example.jp") }

    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      click_on I18n.t('ss.links.download_template')

      csv = CSV.parse(page.html.encode("UTF-8"), headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers).to have(Webmail::AccountExport::EXPORT_DEF.length).items
    end
  end

  context "import accounts_1.csv" do
    let!(:user1) { create(:ss_user, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:ss_user, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:ss_user, id: 103, email: "#{unique_id}-3@example.jp") }
    let!(:user4) { create(:ss_user, id: 104, email: "#{unique_id}-4@example.jp") }
    let!(:user5) { create(:ss_user, id: 105, email: "#{unique_id}-5@example.jp") }

    it do
      expect(user1).to have(0).imap_settings
      expect(user2).to have(0).imap_settings
      expect(user3).to have(0).imap_settings
      expect(user4).to have(0).imap_settings
      expect(user5).to have(0).imap_settings

      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/accounts_1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user1.reload
      expect(user1).to have(1).imap_settings
      user1.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq '規定の設定1'
        expect(imap_setting.from).to eq 'ユーザー1'
        expect(imap_setting.address).to eq 'user1@example.jp'
        expect(imap_setting.imap_alias).to eq 'user1@blue.example.jp'
        expect(imap_setting.imap_host).to eq 'imap1.example.jp'
        expect(imap_setting.imap_port).to eq 123
        expect(imap_setting.imap_ssl_use).to eq 'enabled'
        expect(imap_setting.imap_auth_type).to eq 'PLAIN'
        expect(imap_setting.imap_account).to eq 'user1@example.jp'
        expect(imap_setting.decrypt_imap_password).to eq 'pass1'
        expect(imap_setting.threshold_mb).to eq 987
        expect(imap_setting.imap_sent_box).to eq 'INBOX.Sent'
        expect(imap_setting.imap_draft_box).to eq 'INBOX.Draft'
        expect(imap_setting.imap_trash_box).to eq 'INBOX.Trash'
      end
      expect(user1.imap_default_index).to eq 0

      user2.reload
      expect(user2).to have(1).imap_settings

      user3.reload
      expect(user3).to have(1).imap_settings

      user4.reload
      expect(user4).to have(1).imap_settings

      user5.reload
      expect(user5).to have(1).imap_settings
    end
  end

  context "import old_accounts_1-1.csv" do
    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/old_accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user = SS::User.find(1)
      sys_account = user.imap_settings[0]
      expect(sys_account.name).to eq "sys"
      expect(sys_account.from).to eq "ユーザー1"
      expect(sys_account.address).to eq "sys@example.jp"
      expect(sys_account.imap_host).to eq "example.jp"
      expect(sys_account.imap_auth_type).to eq "CRAM-MD5"
      expect(sys_account.threshold_mb).to eq 123
      expect(sys_account.imap_sent_box).to eq "INBOX.Sent"
      expect(sys_account.imap_draft_box).to eq "INBOX.Draft"
      expect(sys_account.imap_trash_box).to eq "INBOX.Trash"
      expect(sys_account.decrypt_imap_password).to eq "pass"

      admin_account = user.imap_settings[1]
      expect(admin_account.name).to eq "admin"
      expect(admin_account.from).to eq "ユーザー2"
      expect(admin_account.address).to eq "admin@example.jp"
      expect(admin_account.imap_host).to eq "example.jp"
      expect(admin_account.imap_auth_type).to eq "PLAIN"
      expect(admin_account.threshold_mb).to eq 234
      expect(admin_account.imap_sent_box).to eq "INBOX.Sent"
      expect(admin_account.imap_draft_box).to eq "INBOX.Draft"
      expect(admin_account.imap_trash_box).to eq "INBOX.Trash"
      expect(admin_account.decrypt_imap_password).to eq "pass"

      user_account = user.imap_settings[2]
      expect(user_account.name).to eq "user1"
      expect(user_account.from).to eq "ユーザー3"
      expect(user_account.address).to eq "user1@example.jp"
      expect(user_account.imap_host).to eq "example.jp"
      expect(user_account.imap_auth_type).to eq ""
      expect(user_account.threshold_mb).to eq 345
      expect(user_account.imap_sent_box).to eq "INBOX.Sent"
      expect(user_account.imap_draft_box).to eq "INBOX.Draft"
      expect(user_account.imap_trash_box).to eq "INBOX.Trash"
      expect(user_account.decrypt_imap_password).to eq "pass"
    end
  end

  context "import old_accounts_1-1.csv and overwrite with old_accounts_1-2.csv" do
    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/old_accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/old_accounts_1-2.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user = SS::User.find(1)
      sys_account = user.imap_settings[0]
      expect(sys_account.name).to eq "edit"
      expect(sys_account.from).to eq "ユーザー1"
      expect(sys_account.address).to eq "edit@example.jp"
      expect(sys_account.imap_host).to eq "example.jp"
      expect(sys_account.imap_auth_type).to eq ""
      expect(sys_account.threshold_mb).to eq 123
      expect(sys_account.imap_sent_box).to eq "INBOX.Sent"
      expect(sys_account.imap_draft_box).to eq "INBOX.Draft"
      expect(sys_account.imap_trash_box).to eq "INBOX.Trash"
      expect(sys_account.decrypt_imap_password).to eq "pass"

      admin_account = user.imap_settings[1]
      expect(admin_account.name).to eq "admin"
      expect(admin_account.from).to eq "ユーザー2"
      expect(admin_account.address).to eq "admin@example.jp"
      expect(admin_account.imap_host).to eq "example.jp"
      expect(admin_account.imap_auth_type).to eq "PLAIN"
      expect(admin_account.threshold_mb).to eq 234
      expect(admin_account.imap_sent_box).to eq "INBOX.Sent"
      expect(admin_account.imap_draft_box).to eq "INBOX.Draft"
      expect(admin_account.imap_trash_box).to eq "INBOX.Trash"
      expect(admin_account.decrypt_imap_password).to eq "pass"

      user_account = user.imap_settings[2]
      expect(user_account.name).to eq "user1"
      expect(user_account.from).to eq "ユーザー3"
      expect(user_account.address).to eq "user1@example.jp"
      expect(user_account.imap_host).to eq "example.jp"
      expect(user_account.imap_auth_type).to eq ""
      expect(user_account.threshold_mb).to eq 345
      expect(user_account.imap_sent_box).to eq "INBOX.Sent"
      expect(user_account.imap_draft_box).to eq "INBOX.Draft"
      expect(user_account.imap_trash_box).to eq "INBOX.Trash"
      expect(user_account.decrypt_imap_password).to eq "pass"
    end
  end
end
