require 'spec_helper'

describe "webmail_account", type: :feature, dbscope: :example do
  before { login_webmail_user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:from) { unique_id }
    let(:imap_alias) { "#{from}-alias@example.jp" }
    let(:imap_account) { from }
    let(:imap_password) { unique_id }

    it do
      visit webmail_account_path(account: 0)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[from]", with: from
        fill_in "item[imap_alias]", with: imap_alias
        fill_in "item[imap_account]", with: imap_account
        fill_in "item[in_imap_password]", with: imap_password
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      webmail_user.tap do |item|
        item.reload
        expect(item.imap_settings.length).to eq 1
        item.imap_settings.first.tap do |imap_setting|
          expect(imap_setting.name).to eq name
          expect(imap_setting.from).to eq from
          expect(imap_setting.imap_alias).to eq imap_alias
          expect(imap_setting.imap_account).to eq imap_account
          expect(imap_setting.decrypt_imap_password).to eq imap_password
        end
      end
    end
  end
end
