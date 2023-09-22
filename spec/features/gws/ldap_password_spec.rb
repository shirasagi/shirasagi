require 'spec_helper'
require "csv"
Selenium::WebDriver.logger
describe "ldap_pass_change", type: :feature, dbscope: :example, ldap: true, js: true do
  context 'パスワード変更' do
    let(:username) { "uid=admin,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
    let(:host) { SS.config.ldap.host }

    context 'アカウントのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      before do
        login_gws_user
        visit gws_user_path(site: gws_site, id: gws_user.id)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[ldap_dn]", with: username
          click_on I18n.t("ss.buttons.save")
        end
      end
      it do
        visit sns_cur_user_account_path
        expect(page).to have_content(I18n.t("ss.links.edit_password"))
        click_on I18n.t("ss.links.edit_password")
        within "form#item-form" do
          fill_in "item[old_password]", with: password
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password
          page.save_screenshot "formed_sns_cur_user_account.png"
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

    context 'プロフィールのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      before do
        login_gws_user
        visit gws_user_path(site: gws_site, id: gws_user.id)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[ldap_dn]", with: username
          click_on I18n.t("ss.buttons.save")
        end
      end

      it do
        visit gws_user_profile_path(site: gws_site)
        click_on I18n.t("ss.links.edit_password")
        within "form#item-form" do
          fill_in "item[old_password]", with: password
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

    context 'ユーザーのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      before do
        login_gws_user
        visit gws_user_path(site: gws_site, id: gws_user.id)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[ldap_dn]", with: username
          fill_in "item[in_password]", with: password
          click_on I18n.t("ss.buttons.save")
        end

      end

      it do
        visit gws_user_path(site: gws_site, id: gws_user.id)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[in_password]", with: new_password
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

    context 'ユーザーダウンロードのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      let(:name) { "user1" }
      before do
        login_gws_user
        visit gws_users_path(site: gws_site)
        click_on I18n.t('ss.buttons.new')
        wait_for_js_ready
        first('.mod-gws-user-groups').click_on I18n.t('ss.apis.groups.index')
        wait_for_cbox
        first('tbody.items a.select-item').click
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[email]", with: "#{name}@example.jp"
          expect(page).to have_css('#item_email_errors', text: '')
          fill_in "item[in_password]", with: "pass"
          click_on I18n.t('ss.buttons.save')
        end
      end

      it do
        visit gws_users_path(site: gws_site)
        click_on I18n.t("ss.links.import")
        within ".main-box" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ldap/ldap_user_test.csv" #"#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        end
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

    context 'メールのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      before do
        login_webmail_admin
      end
      it do
        visit webmail_user_path(id: webmail_admin.id)

        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[in_password]", with: new_password
          fill_in "item[ldap_dn]", with: username
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

    context 'メールダウンロードのパスワード変更' do
      let(:password) { "pass" }
      let(:new_password) { "password" }
      let(:name) { "user1" }
      before do
        login_webmail_admin
        visit webmail_users_path
        click_on I18n.t('ss.buttons.new')
        wait_for_js_ready
        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[email]", with: "#{name}@example.jp"
          expect(page).to have_css('#item_email_errors', text: '')
          fill_in "item[in_password]", with: "pass"
          click_on I18n.t('ss.buttons.save')
        end
      end

      it do
        visit webmail_users_path
        within ".nav-menu" do
          click_on I18n.t("ss.links.import")
        end
        within ".main-box" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ldap/ldap_user_test.csv" #"#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        end
        within ".send" do
          click_on I18n.t("ss.links.import")
        end

        expect(Ldap::Connection.authenticate(username: username, password: password)).to be false
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be true
      end
    end

  end
end