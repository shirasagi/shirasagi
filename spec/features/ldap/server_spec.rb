require 'spec_helper'

describe "ldap_server", ldap: true do
  context "with ldap site" do
    let(:group) do
      create(:cms_group, name: unique_id, ldap_host: ENV["ldap_host"],
             ldap_dn: "dc=city,dc=shirasagi,dc=jp", ldap_auth_method: "anonymous")
    end
    let(:site) do
      create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
             group_ids: [group.id])
    end
    let(:role) do
      create(:cms_user_role, name: "ldap_user_role_#{unique_id}", site_id: site.id)
    end
    let(:user) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
             group_ids: [group.id], cms_role_ids: [role.id])
    end
    let(:index_path) { ldap_server_path site.host }
    let(:group_dn) { "ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    let(:user_dn) { "uid=user1,ou=001002秘書広報課,ou=001企画部, dc=city, dc=shirasagi, dc=jp" }
    let(:index2_path) { "/.#{site.host}/ldap/server/#{URI.escape(group_dn)}" }
    let(:group_path) { "/.#{site.host}/ldap/server/#{URI.escape(group_dn)}/group" }
    let(:user_path) { "/.#{site.host}/ldap/server/#{URI.escape(user_dn)}/user" }

    after :all do
      group.delete if group.present?
      site.delete if site.present?
      role.delete if role.present?
      user.delete if user.present?
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
        login_cms_user(user)
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end

      it "#index with dn" do
        login_cms_user(user)
        visit index2_path
        expect(status_code).to eq 200
        expect(current_path).to eq index2_path
      end

      it "#group" do
        login_cms_user(user)
        visit group_path
        expect(status_code).to eq 200
        expect(current_path).to eq group_path
      end

      it "#user" do
        login_cms_user(user)
        visit user_path
        expect(status_code).to eq 200
        expect(current_path).to eq user_path
      end
    end
  end

  context "with non-ldap site" do
    let(:site) { cms_site }
    let(:index_path) { ldap_server_path site.host }

    context "with auth" do
      it "#index" do
        login_cms_user
        visit index_path
        expect(status_code).to eq 400
        expect(current_path).to eq index_path
        expect(page).to have_selector("div#errorExplanation h2")
        expect(page).to have_selector("div#errorExplanation ul")
      end
    end
  end
end
