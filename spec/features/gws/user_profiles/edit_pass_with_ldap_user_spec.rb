require 'spec_helper'

describe "gws_user_profiles", type: :feature, dbscope: :example, ldap: true, js: true do
  let!(:site) { gws_site }
  let(:ldap_url) { "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/" }
  let!(:user) { create :gws_ldap_user2, organization: site, group_ids: [ site.id ] }

  shared_examples 'パスワード変更' do
    let(:new_password) { unique_id }

    before do
      expect(Ldap::Connection.authenticate(url: ldap_url, username: user.ldap_dn, password: "pass")).to be_truthy

      visit gws_login_path(site: site)
      within "form" do
        fill_in "item[email]", with: user.email.presence || user.uid
        fill_in "item[password]", with: "pass"
        click_on I18n.t("ss.login", locale: I18n.default_locale)
      end
      expect(page).to have_css("nav.user .user-name", text: user.name)

      # rubocop:disable Rails/I18nLocaleAssignment
      if user.lang.present?
        I18n.locale = user.lang.to_sym
      end
      # rubocop:enable Rails/I18nLocaleAssignment
    end

    after do
      # ldap password を変更したのでldap serviceを削除（ldapデータベースを削除する方法を探したが見つからなかった）
      stop_ldap_service
    end

    it do
      visit gws_user_profile_path(site: site)
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
      visit gws_login_path(site: site)
      within "form" do
        fill_in "item[email]", with: user.email.presence || user.uid
        fill_in "item[password]", with: new_password
        click_on I18n.t("ss.login", locale: I18n.default_locale)
      end
      expect(current_path).to eq gws_portal_path(site: site)
      expect(page).to have_css("nav.user .user-name", text: user.name)
    end
  end

  context "with site setting" do
    before do
      site.ldap_use_state = "individual"
      site.ldap_url = ldap_url
      site.save!
    end

    it_behaves_like 'パスワード変更'
  end

  context "with system setting" do
    before do
      auth_setting = Sys::Auth::Setting.instance
      auth_setting.ldap_url = ldap_url
      auth_setting.save!
    end

    after { ActiveSupport::CurrentAttributes.reset_all }

    it_behaves_like 'パスワード変更'
  end
end
