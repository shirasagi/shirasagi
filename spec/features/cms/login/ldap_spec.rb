require 'spec_helper'

describe "cms_login", type: :feature, dbscope: :example, js: true, ldap: true do
  let(:site) { cms_site }
  let!(:ldap_user) do
    create :cms_ldap_user2, organization: site.groups.first, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids
  end

  shared_examples "ldap user login on cms" do
    context "by uid" do
      it do
        visit cms_login_path(site: site)

        within "form" do
          fill_in "item[email]", with: ldap_user.uid
          fill_in "item[password]", with: "pass"
          click_on I18n.t("ss.login")
        end
        expect(current_path).to eq cms_contents_path(site: site)
        expect(page).to have_css("nav.user .user-name", text: ldap_user.name)
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
        expect(page).to have_css("nav.user .user-name", text: ldap_user.name)
      end
    end
  end

  context "with site setting" do
    before do
      site.ldap_use_state = "individual"
      site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      site.save!
    end

    include_context "ldap user login on cms"
  end

  context "with system setting" do
    before do
      auth_setting = Sys::Auth::Setting.first_or_create
      auth_setting.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      auth_setting.save!
    end

    include_context "ldap user login on cms"
  end
end
