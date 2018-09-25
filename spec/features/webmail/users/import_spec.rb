require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

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
    end
  end
end
