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
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect { Webmail::User.all.find_by(uid: uid) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      expect { Webmail::User.all.find_by(uid: uid2) }.to raise_error(Mongoid::Errors::DocumentNotFound)
    end
  end
end
