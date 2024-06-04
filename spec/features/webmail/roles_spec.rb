require 'spec_helper'

describe "webmail_roles", type: :feature, dbscope: :example do
  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }

    before { login_webmail_admin }

    it do
      visit webmail_roles_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        check "item_permissions_use_webmail_group_imap_setting"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      Webmail::Role.all.find_by(name: name).tap do |item|
        expect(item.permission_level).to eq 1
        expect(item.permissions).to include("use_webmail_group_imap_setting")
      end

      visit webmail_roles_path
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect { Webmail::Role.all.find_by(name: name) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      Webmail::Role.all.find_by(name: name2).tap do |item|
        expect(item.permission_level).to eq 1
        expect(item.permissions).to include("use_webmail_group_imap_setting")
      end

      visit webmail_roles_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { Webmail::Role.all.find_by(name: name) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      expect { Webmail::Role.all.find_by(name: name2) }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end
end
