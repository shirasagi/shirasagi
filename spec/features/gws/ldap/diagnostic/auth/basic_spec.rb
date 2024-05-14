require 'spec_helper'

describe "gws_ldap_diagnostic_auth", type: :feature, dbscope: :example, ldap: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  before do
    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    login_user user
  end

  context "with valid dn / password" do
    let(:dn) { "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass" }

    it do
      visit gws_ldap_diagnostic_auth_path(site: site)

      within "form#item-form" do
        fill_in "item[dn]", with: dn
        fill_in "item[password]", with: password
        click_on I18n.t("sys.diag")
      end

      expect(page).to have_css(".result", text: "success")
    end
  end

  context "with valid dn" do
    let(:dn) { "uid=user99, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "pass" }

    it do
      visit gws_ldap_diagnostic_auth_path(site: site)

      within "form#item-form" do
        fill_in "item[dn]", with: dn
        fill_in "item[password]", with: password
        click_on I18n.t("sys.diag")
      end

      expect(page).to have_css(".result", text: "failed")
    end
  end

  context "with valid password" do
    let(:dn) { "uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp" }
    let(:password) { "1234" }

    it do
      visit gws_ldap_diagnostic_auth_path(site: site)

      within "form#item-form" do
        fill_in "item[dn]", with: dn
        fill_in "item[password]", with: password
        click_on I18n.t("sys.diag")
      end

      expect(page).to have_css(".result", text: "failed")
    end
  end
end
