require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example, js: true do
  before { login_webmail_admin }

  context "basic crud" do
    let(:name) { unique_id }
    let(:uid) { unique_id }
    let(:email) { "#{uid}@example.jp" }
    let(:password) { unique_id }
    let(:uid2) { unique_id }
    let(:email2) { "#{uid2}@example.jp" }
    let(:index_path) { webmail_users_path }
    let(:delete_path) { "#{index_path}/#{webmail_user.id}/delete" }

    it do
      visit webmail_users_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[uid]", with: uid
        fill_in "item[email]", with: email
        expect(page).to have_css('#item_uid_errors', text: '')
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: password
        check "item_webmail_role_ids_#{webmail_user_role.id}"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      Webmail::User.all.find_by(uid: uid).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
        expect(item.active?).to be_truthy
      end

      visit webmail_users_path
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[uid]", with: uid2
        fill_in "item[email]", with: email2
        expect(page).to have_css('#item_uid_errors', text: '')
        expect(page).to have_css('#item_email_errors', text: '')
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect { Webmail::User.all.find_by(uid: uid) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email2
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
        expect(item.active?).to be_truthy
      end

      visit webmail_users_path
      click_on name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect { Webmail::User.all.find_by(uid: uid) }.to raise_error(Mongoid::Errors::DocumentNotFound)
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email2
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
        expect(item.active?).to be_falsey
      end

      visit webmail_users_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[uid]", with: uid
        fill_in "item[email]", with: email
        expect(page).to have_css('#item_uid_errors', text: '')
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: password
        check "item_webmail_role_ids_#{webmail_user_role.id}"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      Webmail::User.all.find_by(uid: uid).tap do |item|
        expect(item.name).to eq name
        expect(item.email).to eq email
        expect(item.webmail_role_ids).to include(webmail_user_role.id)
        expect(item.active?).to be_truthy
      end
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.active?).to be_falsey
      end

      visit edit_webmail_user_path(id: Webmail::User.all.find_by(uid: uid2).id)
      within "form#item-form" do
        fill_in "item[account_expiration_date]", with: nil
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      Webmail::User.all.find_by(uid: uid).tap do |item|
        expect(item.active?).to be_truthy
      end
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.active?).to be_truthy
      end

      visit webmail_users_path
      find("input[value='#{Webmail::User.all.find_by(uid: uid).id}']").check
      within '.list-head' do
        page.accept_confirm do
          click_button I18n.t('ss.links.delete')
        end
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      Webmail::User.all.find_by(uid: uid).tap do |item|
        expect(item.active?).to be_falsey
      end
      Webmail::User.all.find_by(uid: uid2).tap do |item|
        expect(item.active?).to be_truthy
      end

      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))
      expect { Webmail::User.all.active.find(webmail_user.id) }.to raise_error Mongoid::Errors::DocumentNotFound

      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))
      expect { Webmail::User.all.find(webmail_user.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
