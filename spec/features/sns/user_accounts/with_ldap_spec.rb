require 'spec_helper'

describe "ldap_pass_change", type: :feature, dbscope: :example, ldap: true, js: true do
  let(:ldap_url) { "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/" }
  let!(:user) { create :ss_ldap_user2 }

  before do
    auth_setting = Sys::Auth::Setting.first_or_create
    auth_setting.ldap_url = ldap_url
    auth_setting.save!

    expect(Ldap::Connection.authenticate(url: ldap_url, username: user.ldap_dn, password: "pass")).to be_truthy
    login_user user
  end

  after do
    # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
    stop_ldap_service
  end

  context 'パスワード変更' do
    let(:new_password) { unique_id }

    it do
      visit sns_cur_user_account_path
      click_on I18n.t("ss.links.edit_password")
      within "form#item-form" do
        fill_in "item[old_password]", with: "pass"
        fill_in "item[new_password]", with: new_password
        fill_in "item[new_password_again]", with: new_password
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Ldap::Connection.authenticate(url: ldap_url, username: user.ldap_dn, password: "pass")).to be_falsey
      expect(Ldap::Connection.authenticate(url: ldap_url, username: user.ldap_dn, password: new_password)).to be_truthy

      # login with new password
      visit sns_login_path
      within "form" do
        fill_in "item[email]", with: user.email.presence || user.uid
        fill_in "item[password]", with: new_password
        click_on I18n.t("ss.login", locale: I18n.default_locale)
      end
      expect(current_path).to eq sns_mypage_path
      expect(page).to have_css("nav.user .user-name", text: user.name)
    end
  end
end
