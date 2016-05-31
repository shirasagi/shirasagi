require 'spec_helper'

describe "ldap_server", ldap: true do
  context "with ldap site" do
    let(:group) do
      create(:cms_group, name: unique_id, ldap_dn: "dc=city,dc=shirasagi,dc=jp")
    end
    let(:site) do
      create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
             group_ids: [group.id])
    end
    let(:role) do
      create(:cms_role_admin, name: "ldap_user_role_#{unique_id}", site_id: site.id)
    end
    let(:user) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
             group_ids: [group.id], cms_role_ids: [role.id])
    end
    let(:index_path) { ldap_server_path site.id }
    let(:group_dn) { "ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    let(:user_dn) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    let(:index2_path) { "/.s#{site.id}/ldap/server/#{URI.escape(group_dn)}" }
    let(:group_path) { "/.s#{site.id}/ldap/server/#{URI.escape(group_dn)}/group" }
    let(:user_path) { "/.s#{site.id}/ldap/server/#{URI.escape(user_dn)}/user" }

    around(:each) do |example|
      save_auth_method = SS.config.ldap.auth_method
      SS.config.replace_value_at(:ldap, :auth_method, "anonymous")
      example.run
      SS.config.replace_value_at(:ldap, :auth_method, save_auth_method)
    end

    it "without login" do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end

    context "with auth" do
      it "#index" do
        login_user(user)
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end

      it "#index with dn" do
        login_user(user)
        visit index2_path
        expect(status_code).to eq 200
        expect(current_path).to eq index2_path
      end

      it "#group" do
        login_user(user)
        visit group_path
        expect(status_code).to eq 200
        expect(current_path).to eq group_path
      end

      it "#user" do
        login_user(user)
        visit user_path
        expect(status_code).to eq 200
        expect(current_path).to eq user_path
      end
    end
  end

  context "with non-ldap site" do
    let(:site) { cms_site }
    let(:index_path) { ldap_server_path site.id }

    context "with auth" do
      it "#index" do
        login_cms_user
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_selector("div#errorExplanation h2", text: I18n.t("errors.template.header.one"))
        expect(page).to have_selector("div#errorExplanation ul li", text: "Invalid binding information")
      end
    end
  end
end
