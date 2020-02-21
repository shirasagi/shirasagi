require 'spec_helper'

describe "ldap_server", type: :feature, dbscope: :example do
  context "without ldap site" do
    let(:site) { cms_site }
    let(:index_path) { ldap_server_path site.id }
    let(:group) { create :ss_group, name: 'group' }

    it "#index" do
      login_cms_user
      visit index_path
      expect(page).to have_css ".ldap-server-header"
    end

    it "#index with multiple root groups" do
      site.group_ids += [group.id]
      site.save!

      login_cms_user
      visit index_path
      expect(page).to have_css ".ldap-server-header"
    end
  end

  context "with ldap site", ldap: true do
    let(:group) do
      create(:cms_group, name: unique_id, ldap_dn: "dc=example,dc=jp")
    end
    let(:site) do
      create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
             group_ids: [group.id])
    end
    let(:role) do
      create(:cms_role_admin, name: "ldap_user_role_#{unique_id}", site_id: site.id)
    end
    let(:user) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "admin",
             ldap_dn: "cn=admin,dc=example,dc=jp",
             group_ids: [group.id], cms_role_ids: [role.id])
    end
    let(:index_path) { ldap_server_path site.id }
    let(:group_dn) { "ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
    let(:user_dn) { "uid=user1,ou=001001政策課,ou=001企画政策部,dc=example,dc=jp" }
    let(:index2_path) { "/.s#{site.id}/ldap/server/#{URI.escape(group_dn)}" }
    let(:group_path) { "/.s#{site.id}/ldap/server/#{URI.escape(group_dn)}/group" }
    let(:user_path) { "/.s#{site.id}/ldap/server/#{URI.escape(user_dn)}/user" }

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

  context "with non-ldap site", ldap: true do
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
