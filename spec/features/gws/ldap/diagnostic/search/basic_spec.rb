require 'spec_helper'

describe "gws_ldap_diagnostic_search", type: :feature, dbscope: :example, ldap: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  before do
    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    login_user user
  end

  context "with default scope" do
    let(:user_dn) { "cn=admin,dc=example,dc=jp" }
    let(:user_password) { "admin" }
    let(:base_dn) { "dc=example,dc=jp" }

    it do
      visit gws_ldap_diagnostic_search_path(site: site)

      within "form#item-form" do
        fill_in "item[user_dn]", with: user_dn
        fill_in "item[user_password]", with: user_password
        fill_in "item[base_dn]", with: base_dn

        click_on I18n.t("ss.buttons.search")
      end

      within "#addon-result" do
        expect(page).to have_css("tbody tr", count: 16)
      end
    end
  end
end
