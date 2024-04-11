require 'spec_helper'

describe "ldap_pass_change", type: :feature, dbscope: :example, ldap: true, js: true do
  let(:ldap_url) { "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/" }

  around do |example|
    save = ::Ldap.sync_password
    ::Ldap.sync_password = "enable"
    example.run
  ensure
    ::Ldap.sync_password = save
  end

  context 'パスワード変更' do
    let(:username) { "uid=admin,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }

    context 'ユーザーのパスワード変更' do
      let(:new_password) { "password" }

      before do
        auth_setting = Sys::Auth::Setting.first_or_create
        auth_setting.ldap_url = ldap_url
        auth_setting.save!

        gws_user.update!(type: Gws::User::TYPE_LDAP, ldap_dn: username)
        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: gws_user.in_password)).to \
          be_truthy
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

        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: gws_user.in_password)).to \
          be_falsey
        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: new_password)).to be_truthy
      end
    end

    context 'ユーザーダウンロードのパスワード変更' do
      let(:new_password_in_csv) { "password" }
      let(:name) { "user1" }
      let!(:user_in_csv) do
        create(
          :gws_user, name: name, email: "#{name}@example.jp", type: Gws::User::TYPE_LDAP,
          ldap_dn: "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp")
      end

      before do
        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: user_in_csv.in_password)).to \
          be_truthy
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
          auth = { url: ldap_url, username: modified_user.ldap_dn, password: "pass" }
          expect(Ldap::Connection.authenticate(**auth)).to be_falsey
          auth = { url: ldap_url, username: modified_user.ldap_dn, password: new_password_in_csv }
          expect(Ldap::Connection.authenticate(**auth)).to be_truthy
        end
      end
    end

    context 'Webメールのパスワード変更' do
      let(:username) { "uid=admin,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
      let(:new_password) { unique_id }

      before do
        auth_setting = Sys::Auth::Setting.first_or_create
        auth_setting.ldap_url = ldap_url
        auth_setting.save!

        webmail_admin.update!(type: Gws::User::TYPE_LDAP, ldap_dn: username)

        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: webmail_admin.in_password)).to \
          be_truthy
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

        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: webmail_admin.in_password)).to \
          be_falsey
        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: new_password)).to be_truthy
      end
    end

    context 'Webメールダウンロードのパスワード変更' do
      let(:new_password_in_csv) { "password" }
      let(:name) { "user1" }
      let!(:user_in_csv) do
        create(
          :webmail_user, name: name, email: "#{name}@example.jp", type: Webmail::User::TYPE_LDAP,
          ldap_dn: "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp"
        )
      end

      before do
        expect(Ldap::Connection.authenticate(url: ldap_url, username: username, password: user_in_csv.in_password)).to \
          be_truthy
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
          auth = { url: ldap_url, username: modified_user.ldap_dn, password: "pass" }
          expect(Ldap::Connection.authenticate(**auth)).to be_falsey
          auth = { url: ldap_url, username: modified_user.ldap_dn, password: new_password_in_csv }
          expect(Ldap::Connection.authenticate(**auth)).to be_truthy
        end
      end
    end
  end
end
