require 'spec_helper'

describe "webmail_groups", type: :feature, dbscope: :example do
  before { login_webmail_admin }
  let!(:group0) { create(:webmail_group_with_no_imap, id: 100, order: 100, name: "テスト市") }
  let!(:group1) { create(:webmail_group_with_no_imap, id: 101, order: 101, name: "テスト市/グループA") }
  let!(:group2) { create(:webmail_group_with_no_imap, id: 102, order: 102, name: "テスト市/グループB") }
  let!(:group3) { create(:webmail_group_with_no_imap, id: 103, order: 103, name: "テスト市/グループC") }
  let!(:group4) { create(:webmail_group_with_no_imap, id: 104, order: 104, name: "テスト市/グループD") }

  context "download template" do
    it do
      visit webmail_groups_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      click_on I18n.t('ss.links.download_template')

      csv = CSV.parse(page.html.encode("UTF-8"), headers: true)
      expect(csv).to have_at_least(1).items
      expect(csv.headers).to have(Webmail::GroupExport::EXPORT_DEF.length).items
      expect(csv.headers.include?(Webmail::GroupExport::EXPORT_DEF.sample[:label])).to be_truthy
    end
  end

  context "import group_accounts_1-1.csv" do
    it do
      expect(group0).to have(0).imap_settings
      expect(group1).to have(0).imap_settings
      expect(group2).to have(0).imap_settings
      expect(group3).to have(0).imap_settings
      expect(group4).to have(0).imap_settings

      visit webmail_groups_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/group_accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      group0.reload
      expect(group0).to have(0).imap_settings

      group1.reload
      expect(group1).to have(1).imap_settings
      group1.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq 'テスト市・グループA'
        expect(imap_setting.from).to eq 'グループA'
        expect(imap_setting.address).to eq 'group-a@test.example.jp'
        expect(imap_setting.imap_host).to eq 'imap.test.example.jp'
        expect(imap_setting.imap_port).to eq 123
        expect(imap_setting.imap_ssl_use).to eq 'disabled'
        expect(imap_setting.imap_auth_type).to eq 'PLAIN'
        expect(imap_setting.imap_account).to eq 'group-a'
        expect(imap_setting.decrypt_imap_password).to eq 'pass-a'
        expect(imap_setting.threshold_mb).to eq 987
        expect(imap_setting.imap_sent_box).to eq 'INBOX.Sent'
        expect(imap_setting.imap_draft_box).to eq 'INBOX.Draft'
        expect(imap_setting.imap_trash_box).to eq 'INBOX.Trash'
      end

      group2.reload
      expect(group2).to have(1).imap_settings

      group3.reload
      expect(group3).to have(1).imap_settings

      group4.reload
      expect(group4).to have(1).imap_settings

      # newly created group
      group5 = Webmail::Group.find_by(name: "テスト市/グループE")
      expect(group5).to have(1).imap_settings
    end
  end

  context "import group_accounts_1-1.csv and overwrite with group_accounts_1-2.csv" do
    it do
      visit webmail_groups_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/group_accounts_1-1.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      visit webmail_groups_path
      within ".nav-menu" do
        click_on I18n.t("ss.links.import")
      end
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/webmail/group_accounts_1-2.csv"
        click_button I18n.t("ss.import")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      group0.reload
      expect(group0).to have(0).imap_settings

      group1.reload
      expect(group1).to have(1).imap_settings

      group2.reload
      expect(group2).to have(1).imap_settings

      group3.reload
      expect(group3).to have(1).imap_settings
      group3.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq 'テスト市・グループC - edit'
      end

      # group4 was also overwrote because id is missing but name is same
      group4.reload
      expect(group4).to have(1).imap_settings
      group4.imap_settings.first.tap do |imap_setting|
        expect(imap_setting.name).to eq 'テスト市・グループD - edit'
      end
    end
  end
end
