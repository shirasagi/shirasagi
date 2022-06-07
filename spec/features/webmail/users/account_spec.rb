require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example, js: true do
  let(:name) { "name-#{unique_id}" }
  let(:from) { "from-#{unique_id}" }
  let(:address) { "address-#{unique_id}@example.jp" }
  let(:imap_alias) { "alias-#{unique_id}@example.jp" }
  let(:imap_host) { "host-#{unique_id}.example.jp" }
  let(:imap_port) { rand(1..100) }
  let(:imap_ssl_use) { %w(disabled enabled).sample }
  let(:imap_ssl_use_label) { I18n.t("webmail.options.imap_ssl_use.#{imap_ssl_use}") }
  let(:imap_auth_type) { %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5).sample }
  let(:imap_auth_type_label) { imap_auth_type }
  let(:imap_account) { "account-#{unique_id}" }
  let(:imap_password) { "password-#{unique_id}" }
  let(:imap_sent_box) { "sent-#{unique_id}" }
  let(:imap_draft_box) { "draft-#{unique_id}" }
  let(:imap_trash_box) { "trash-#{unique_id}" }
  let(:threshold_mb) { rand(1..100) }

  before { login_webmail_admin }

  context "default account crud" do
    it do
      expect(webmail_user.imap_default_index).to eq 0
      expect(webmail_user.imap_settings).to be_blank

      visit webmail_users_path
      click_on webmail_user.name
      click_on I18n.t("webmail.default_settings")
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[from]", with: from
        fill_in "item[address]", with: address
        fill_in "item[imap_alias]", with: imap_alias
        fill_in "item[imap_host]", with: imap_host
        fill_in "item[imap_port]", with: imap_port
        select imap_ssl_use_label, from: "item[imap_ssl_use]"
        select imap_auth_type_label, from: "item[imap_auth_type]"
        fill_in "item[imap_account]", with: imap_account
        fill_in "item[in_imap_password]", with: imap_password
        fill_in "item[imap_sent_box]", with: imap_sent_box
        fill_in "item[imap_draft_box]", with: imap_draft_box
        fill_in "item[imap_trash_box]", with: imap_trash_box
        fill_in "item[threshold_mb]", with: threshold_mb

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      webmail_user.reload
      expect(webmail_user.imap_default_index).to eq 0
      expect(webmail_user).to have(1).imap_settings
      webmail_user.imap_settings.first.tap do |setting|
        expect(setting[:name]).to eq name
        expect(setting[:from]).to eq from
        expect(setting[:address]).to eq address
        expect(setting[:imap_alias]).to eq imap_alias
        expect(setting[:imap_host]).to eq imap_host
        expect(setting[:imap_port]).to eq imap_port
        expect(setting[:imap_ssl_use]).to eq imap_ssl_use
        expect(setting[:imap_auth_type]).to eq imap_auth_type
        expect(setting[:imap_account]).to eq imap_account
        expect(setting[:imap_password]).to eq SS::Crypto.encrypt(imap_password)
        expect(setting[:imap_sent_box]).to eq imap_sent_box
        expect(setting[:imap_draft_box]).to eq imap_draft_box
        expect(setting[:imap_trash_box]).to eq imap_trash_box
        expect(setting[:threshold_mb]).to eq threshold_mb
      end
    end
  end

  context "alternative account crud" do
    it do
      expect(webmail_user.imap_default_index).to eq 0
      expect(webmail_user.imap_settings).to be_blank

      #
      # Create
      #
      visit webmail_users_path
      click_on webmail_user.name
      click_on I18n.t('webmail.buttons.add_account')

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[from]", with: from
        fill_in "item[address]", with: address
        fill_in "item[imap_alias]", with: imap_alias
        fill_in "item[imap_host]", with: imap_host
        fill_in "item[imap_port]", with: imap_port
        select imap_ssl_use_label, from: "item[imap_ssl_use]"
        select imap_auth_type_label, from: "item[imap_auth_type]"
        fill_in "item[imap_account]", with: imap_account
        fill_in "item[in_imap_password]", with: imap_password
        fill_in "item[imap_sent_box]", with: imap_sent_box
        fill_in "item[imap_draft_box]", with: imap_draft_box
        fill_in "item[imap_trash_box]", with: imap_trash_box
        fill_in "item[threshold_mb]", with: threshold_mb

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      webmail_user.reload
      expect(webmail_user.imap_default_index).to eq 0
      expect(webmail_user).to have(2).imap_settings

      webmail_user.imap_settings.first.tap do |setting|
        expect(setting[:name]).to eq I18n.t("webmail.default_settings")
      end
      webmail_user.imap_settings.second.tap do |setting|
        expect(setting[:name]).to eq name
        expect(setting[:from]).to eq from
        expect(setting[:address]).to eq address
        expect(setting[:imap_alias]).to eq imap_alias
        expect(setting[:imap_host]).to eq imap_host
        expect(setting[:imap_port]).to eq imap_port
        expect(setting[:imap_ssl_use]).to eq imap_ssl_use
        expect(setting[:imap_auth_type]).to eq imap_auth_type
        expect(setting[:imap_account]).to eq imap_account
        expect(setting[:imap_password]).to eq SS::Crypto.encrypt(imap_password)
        expect(setting[:imap_sent_box]).to eq imap_sent_box
        expect(setting[:imap_draft_box]).to eq imap_draft_box
        expect(setting[:imap_trash_box]).to eq imap_trash_box
        expect(setting[:threshold_mb]).to eq threshold_mb
      end

      #
      # Update
      #
      visit webmail_users_path
      click_on webmail_user.name
      click_on name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        check "item[default]"
        click_on I18n.t("ss.buttons.save")
      end

      webmail_user.reload
      expect(webmail_user.imap_default_index).to eq 1
      expect(webmail_user).to have(2).imap_settings

      #
      # Delete
      #
      visit webmail_users_path
      click_on webmail_user.name
      click_on name
      click_on I18n.t("ss.links.delete")

      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end

      webmail_user.reload
      expect(webmail_user.imap_default_index).to eq 0
      expect(webmail_user).to have(1).imap_settings
      webmail_user.imap_settings.first.tap do |setting|
        expect(setting[:name]).to eq I18n.t("webmail.default_settings")
      end
    end
  end
end
