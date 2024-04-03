require 'spec_helper'

describe "cms_login", type: :feature, dbscope: :example, js: true, ldap: true do
  let(:site) { cms_site }
  let!(:ldap_user) do
    create :cms_ldap_user2, organization: site, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids
  end

  context "with ldap user" do
    before do
      site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      site.save!
    end

    context "by uid" do
      it do
        visit cms_login_path(site: site)

        within "form" do
          fill_in "item[email]", with: ldap_user.uid
          fill_in "item[password]", with: "pass"
          click_on I18n.t("ss.login")
        end
        expect(current_path).to eq cms_contents_path(site: site)
      end
    end

    context "by email" do
      it do
        visit cms_login_path(site: site)

        within "form" do
          fill_in "item[email]", with: ldap_user.email
          fill_in "item[password]", with: "pass"
          click_on I18n.t("ss.login")
        end
        expect(current_path).to eq cms_contents_path(site: site)
      end
    end
  end
end
