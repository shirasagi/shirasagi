require 'spec_helper'

describe "sns_login", type: :feature, dbscope: :example, js: true, ldap: true do
  context "with ldap user" do
    let!(:ldap_user) { create :ss_ldap_user2 }

    before do
      item = Sys::Auth::Setting.first_or_create
      item.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      item.save!
    end

    context "by uid" do
      it do
        visit sns_login_path

        within "form" do
          fill_in "item[email]", with: ldap_user.uid
          fill_in "item[password]", with: "pass"
          click_on I18n.t("ss.login")
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).to have_css("nav.user .user-name", text: ldap_user.name)
      end
    end

    context "by email" do
      it do
        visit sns_login_path

        within "form" do
          fill_in "item[email]", with: ldap_user.email
          fill_in "item[password]", with: "pass"
          click_on I18n.t("ss.login")
        end
        expect(current_path).to eq sns_mypage_path
        expect(page).to have_css("nav.user .user-name", text: ldap_user.name)
      end
    end
  end
end
