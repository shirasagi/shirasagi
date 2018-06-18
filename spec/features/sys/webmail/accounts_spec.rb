require 'spec_helper'

describe "sys_webmail_accounts", type: :feature, dbscope: :example do
  let(:import_path) { import_sys_webmail_accounts_path }

  it "without auth" do
    login_ss_user
    visit import_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_sys_user }

    it "#download" do
      visit import_path
      click_link I18n.t('ss.links.download')
      expect(status_code).to eq 200
    end

    it "#download_template" do
      visit import_path
      click_link I18n.t('ss.links.download_template')
      expect(status_code).to eq 200
    end

    it "#import" do
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/webmail_accounts1.csv"
        click_button I18n.t('ss.links.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq import_path

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

    it "#import with overwrite" do
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/webmail_accounts1.csv"
        click_button I18n.t('ss.links.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq import_path

      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/sys/webmail_accounts2.csv"
        click_button I18n.t('ss.links.import')
      end
      expect(status_code).to eq 200
      expect(current_path).to eq import_path

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
