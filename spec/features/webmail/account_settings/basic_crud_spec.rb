require 'spec_helper'

describe "webmail_account_settings", type: :feature, dbscope: :example do
  before { login_webmail_user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:from) { unique_id }
    let(:address) { "#{from}@example.jp" }
    let(:imap_host) { "imap-#{unique_id}.example.jp" }
    let(:imap_port) { rand(100..999) }
    let(:imap_ssl_use) { %w(enabled disabled).sample }
    let(:imap_ssl_use_label) { I18n.t("webmail.options.imap_ssl_use.#{imap_ssl_use}") }
    let(:imap_auth_type) { %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5).sample }
    let(:imap_auth_type_label) { imap_auth_type }
    let(:imap_account) { address }
    let(:imap_password) { unique_id }
    let(:imap_sent_box) { unique_id }
    let(:imap_draft_box) { unique_id }
    let(:imap_trash_box) { unique_id }
    let(:threshold_mb) { rand(1..99) }

    it do
      visit webmail_account_setting_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[imap_settings][][name]", with: name
        fill_in "item[imap_settings][][from]", with: from
        fill_in "item[imap_settings][][address]", with: address
        fill_in "item[imap_settings][][imap_host]", with: imap_host
        fill_in "item[imap_settings][][imap_port]", with: imap_port
        select imap_ssl_use_label, from: "item[imap_settings][][imap_ssl_use]"
        select imap_auth_type_label, from: "item[imap_settings][][imap_auth_type]"
        fill_in "item[imap_settings][][imap_account]", with: imap_account
        fill_in "item[imap_settings][][in_imap_password]", with: imap_password
        fill_in "item[imap_settings][][imap_sent_box]", with: imap_sent_box
        fill_in "item[imap_settings][][imap_draft_box]", with: imap_draft_box
        fill_in "item[imap_settings][][imap_trash_box]", with: imap_trash_box
        fill_in "item[imap_settings][][threshold_mb]", with: threshold_mb
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      webmail_user.tap do |item|
        item.reload
        expect(item.imap_settings.length).to eq 1
        item.imap_settings.first.tap do |imap_setting|
          expect(imap_setting.name).to eq name
          expect(imap_setting.from).to eq from
          expect(imap_setting.address).to eq address
          expect(imap_setting.imap_host).to eq imap_host
          expect(imap_setting.imap_port).to eq imap_port
          expect(imap_setting.imap_ssl_use).to eq imap_ssl_use
          expect(imap_setting.imap_auth_type).to eq imap_auth_type
          expect(imap_setting.imap_account).to eq imap_account
          expect(imap_setting.decrypt_imap_password).to eq imap_password
          expect(imap_setting.imap_sent_box).to eq imap_sent_box
          expect(imap_setting.imap_draft_box).to eq imap_draft_box
          expect(imap_setting.threshold_mb).to eq threshold_mb
        end
      end
    end
  end
end
