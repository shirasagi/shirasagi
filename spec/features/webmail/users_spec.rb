require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "basic crud" do
    let(:name) { unique_id }
    let(:uid) { unique_id }
    let(:email) { "#{uid}@example.jp" }
    let(:password) { unique_id }
    let(:uid2) { unique_id }
    let(:email2) { "#{uid}@example.jp" }

    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[uid]", with: uid
        fill_in "item[email]", with: email
        fill_in "item[in_password]", with: password
        check "item_webmail_role_ids_#{webmail_user_role.id}"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      Webmail::User.all.find_by(uid: uid).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
      end

      visit webmail_users_path
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[uid]", with: uid2
        fill_in "item[email]", with: email2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect { Webmail::User.all.find_by(uid: uid) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email2
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
      end

      visit webmail_users_path
      click_on name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect { Webmail::User.all.find_by(uid: uid) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      expect { Webmail::User.all.find_by(uid: uid2) }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end

  context "download" do
    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.download")

      csv_lines = CSV.parse(page.html.encode("UTF-8"))
      expect(csv_lines.length).to be > 0
    end
  end

  context "import" do
    let!(:user1) { create(:ss_user, id: 101, email: "#{unique_id}-1@example.jp") }
    let!(:user2) { create(:ss_user, id: 102, email: "#{unique_id}-2@example.jp") }
    let!(:user3) { create(:ss_user, id: 103, email: "#{unique_id}-3@example.jp") }
    let!(:user4) { create(:ss_user, id: 104, email: "#{unique_id}-4@example.jp") }
    let!(:user5) { create(:ss_user, id: 105, email: "#{unique_id}-5@example.jp") }

    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.import")
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/accounts_1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      user1.reload
      user1.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq '規定の設定1'
        expect(imap_setting.from).to eq 'ユーザー1'
        expect(imap_setting.address).to eq 'user1@example.jp'
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
    end
  end
end
