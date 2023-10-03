require 'spec_helper'

describe "ldap_pass_change", type: :feature, dbscope: :example, ldap: true, js: true do
  context 'パスワード変更' do
    let(:username) { "uid=admin,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
    let(:host) { SS.config.ldap.host }

    context 'アカウントのパスワード変更' do
      let(:new_password) { unique_id }

      before do
        gws_user.update!(ldap_dn: username)
        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_truthy
        login_gws_user
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
      end

      it do
        visit sns_cur_user_account_path
        expect(page).to have_content(I18n.t("ss.links.edit_password"))
        click_on I18n.t("ss.links.edit_password")
        within "form#item-form" do
          fill_in "item[old_password]", with: gws_user.in_password
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password
          page.save_screenshot "formed_sns_cur_user_account.png"
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_falsey
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be_truthy
      end
    end

    context 'プロフィールのパスワード変更' do
      let(:new_password) { unique_id }

      before do
        gws_user.update!(ldap_dn: username)
        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_truthy
        login_gws_user
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
      end

      it do
        visit gws_user_profile_path(site: gws_site)
        click_on I18n.t("ss.links.edit_password")
        within "form#item-form" do
          fill_in "item[old_password]", with: gws_user.in_password
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_falsey
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be_truthy
      end
    end

    context 'ユーザーのパスワード変更' do
      let(:new_password) { "password" }

      before do
        gws_user.update!(ldap_dn: username)
        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_truthy
        login_gws_user
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
      end

      it do
        visit gws_user_path(site: gws_site, id: gws_user.id)
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[in_password]", with: new_password
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Ldap::Connection.authenticate(username: username, password: gws_user.in_password)).to be_falsey
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be_truthy
      end
    end

    context 'ユーザーダウンロードのパスワード変更' do
      let(:new_password_in_csv) { "password" }
      let(:name) { "user1" }
      let!(:user_in_csv) { create :gws_user, name: name, email: "#{name}@example.jp", in_password: "pass" }

      before do
        expect(Ldap::Connection.authenticate(username: username, password: user_in_csv.in_password)).to be_truthy
        login_gws_user
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
      end

      it do
        visit gws_users_path(site: gws_site)
        click_on I18n.t("ss.links.import")
        within ".main-box" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ldap/ldap_user_test.csv"
        end
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Gws::User.find(user_in_csv.id).tap do |modified_user|
          expect(modified_user.ldap_dn).to eq "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp"
          expect(Ldap::Connection.authenticate(username: modified_user.ldap_dn, password: user_in_csv.in_password)).to be_falsey
          expect(Ldap::Connection.authenticate(username: modified_user.ldap_dn, password: new_password_in_csv)).to be_truthy
        end
      end
    end

    context 'Webメールのパスワード変更' do
      let(:new_password) { unique_id }

      before do
        expect(Ldap::Connection.authenticate(username: username, password: webmail_admin.in_password)).to be_truthy
        login_webmail_admin
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
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

        expect(Ldap::Connection.authenticate(username: username, password: webmail_admin.in_password)).to be_falsey
        expect(Ldap::Connection.authenticate(username: username, password: new_password)).to be_truthy
      end
    end

    context 'Webメールダウンロードのパスワード変更' do
      let(:new_password_in_csv) { "password" }
      let(:name) { "user1" }
      let!(:user_in_csv) { create :webmail_user, name: name, email: "#{name}@example.jp", in_password: "pass" }

      before do
        expect(Ldap::Connection.authenticate(username: username, password: user_in_csv.in_password)).to be_truthy
        login_webmail_admin
      end

      after do
        # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
        stop_ldap_service
      end

      it do
        visit webmail_users_path
        within ".nav-menu" do
          click_on I18n.t("ss.links.import")
        end
        within ".main-box" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ldap/ldap_webmail_accounts.csv"
        end
        within ".send" do
          click_on I18n.t("ss.links.import")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        Webmail::User.find(user_in_csv.id).tap do |modified_user|
          expect(modified_user.ldap_dn).to eq "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp"
          expect(Ldap::Connection.authenticate(username: modified_user.ldap_dn, password: user_in_csv.in_password)).to be_falsey
          expect(Ldap::Connection.authenticate(username: modified_user.ldap_dn, password: new_password_in_csv)).to be_truthy
        end
      end
    end
  end
end
