require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "download template" do
    let!(:user1) { create(:ss_user, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:ss_user, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:ss_user, id: 103, email: "#{unique_id}-3@example.jp") }

    it do
      visit webmail_users_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      click_on I18n.t('ss.links.download_template')

      csv = CSV.parse(page.html.encode("UTF-8"), headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers).to have(Webmail::UserExport::EXPORT_DEF.length).items
    end
  end

  context "import accounts_1-1.csv" do
    let!(:user1) { create(:webmail_user_without_imap, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:webmail_user_without_imap, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:webmail_user_without_imap, id: 103, email: "#{unique_id}-3@example.jp") }
    let!(:sys_role1) { create(:sys_role_general, name: "一般ユーザー") }

    it do
      expect(user1).to have(0).imap_settings
      expect(user2).to have(0).imap_settings
      expect(user3).to have(0).imap_settings
      expect { Webmail::User.find_by(uid: "test-user4") }.to raise_error Mongoid::Errors::DocumentNotFound

      visit webmail_users_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user1.reload
      expect(user1).to have(1).imap_settings
      expect(user1.name).to eq "テスト・ユーザー1"
      expect(user1.kana).to eq "テスト・ユーザー1"
      expect(user1.uid).to eq "test-user1"
      expect(user1.organization_uid).to eq "100002"
      expect(user1.email).to eq "test-user1@example.jp"
      expect(user1.password).to eq SS::Crypto.crypt("pass-user1")
      expect(user1.tel).to eq "0000-0001"
      expect(user1.tel_ext).to eq "01-001"
      expect(user1.type).to eq "sns"
      expect(user1.initial_password_warning).to be_nil
      expect(user1.organization.name).to eq "シラサギ市"
      expect(user1.group_ids).to eq [ SS::Group.find_by(name: "シラサギ市/企画政策部/政策課").id ]
      expect(user1.webmail_role_ids).to eq [ Webmail::Role.find_by(name: "管理者").id ]
      expect(user1.sys_role_ids).to eq [ Sys::Role.and_general.first.id ]
      user1.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq '規定の設定1'
        expect(imap_setting.from).to eq 'テスト・ユーザー1'
        expect(imap_setting.address).to eq 'test-user1@example.jp'
        expect(imap_setting.imap_alias).to eq 'test-user1@blue.example.jp'
        expect(imap_setting.imap_host).to eq 'imap1.example.jp'
        expect(imap_setting.imap_port).to eq 123
        expect(imap_setting.imap_ssl_use).to eq 'enabled'
        expect(imap_setting.imap_auth_type).to eq 'PLAIN'
        expect(imap_setting.imap_account).to eq 'test-user1@example.jp'
        expect(imap_setting.decrypt_imap_password).to eq 'pass-user1'
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

      # just created
      user4 = Webmail::User.find_by(uid: "test-user4")
      expect(user4).to have(1).imap_settings
    end
  end

  context "import accounts_1-1.csv and overwrite with accounts_1-2.csv" do
    let!(:user1) { create(:webmail_user_without_imap, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:webmail_user_without_imap, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:webmail_user_without_imap, id: 103, email: "#{unique_id}-3@example.jp") }
    let!(:sys_role1) { create(:sys_role_general, name: "一般ユーザー") }

    it do
      expect(user1).to have(0).imap_settings
      expect(user2).to have(0).imap_settings
      expect(user3).to have(0).imap_settings
      expect { Webmail::User.find_by(uid: "test-user4") }.to raise_error Mongoid::Errors::DocumentNotFound

      visit webmail_users_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      visit webmail_users_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/accounts_1-2.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user1.reload
      expect(user1).to have(1).imap_settings
      user1.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq '規定の設定1 - edit'
      end
      expect(user1.imap_default_index).to eq 0

      # user2 was also overwrote because id is missing but uid is same
      user2.reload
      expect(user2).to have(1).imap_settings
      user2.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq '規定の設定2 - edit'
      end
    end
  end
end
