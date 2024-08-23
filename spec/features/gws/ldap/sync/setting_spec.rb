require 'spec_helper'

describe "gws_ldap_sync_setting", type: :feature, dbscope: :example, js: true, ldap: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  before do
    SS::LdapSupport.ldap_add Rails.root.join("spec/fixtures/ldap/shirasagi2.ldif")

    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    login_user user
  end

  after do
    SS::LdapSupport.stop_ldap_service
  end

  shared_examples "gws/ldap/sync/setting is" do
    let(:admin_dn) { "cn=admin,dc=example,dc=jp" }
    let(:admin_password) { "admin" }
    let(:group_base_dn) { "dc=example,dc=jp" }
    let(:group_scope) { "whole_subtree" }
    let(:group_scope_label) { I18n.t("ldap.options.search_scope.#{group_scope}") }
    let(:group_filter) { "(objectClass=ssGroup)" }
    let(:group_root_dn) { "cn=シラサギ市, ou=Users, dc=shirasagi-city, dc=example, dc=jp" }
    let(:user_base_dn) { "dc=example,dc=jp" }
    let(:user_scope) { "whole_subtree" }
    let(:user_scope_label) { I18n.t("ldap.options.search_scope.#{group_scope}") }
    let(:user_filter) { "(objectClass=ssUser)" }
    let!(:user_role) { create :gws_role, cur_site: site }

    it do
      visit gws_ldap_sync_setting_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[admin_dn]", with: admin_dn
        fill_in "item[in_admin_password]", with: admin_password

        fill_in "item[group_base_dn]", with: group_base_dn
        select group_scope_label, from: "item[group_scope]"
        fill_in "item[group_filter]", with: group_filter
        fill_in "item[group_root_dn]", with: group_root_dn

        fill_in "item[user_base_dn]", with: user_base_dn
        select user_scope_label, from: "item[user_scope]"
        fill_in "item[user_filter]", with: user_filter
        check "item_user_role_ids_#{user_role.id}"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Ldap::SyncTask.where(group_id: site).count).to eq 1
      Gws::Ldap::SyncTask.where(group_id: site).first.tap do |task|
        expect(task.admin_dn).to eq admin_dn
        expect(task.admin_password).to eq SS::Crypto.encrypt(admin_password)
        expect(task.group_base_dn).to eq group_base_dn
        expect(task.group_scope).to eq group_scope
        expect(task.group_filter).to eq group_filter
        expect(task.group_root_dn).to eq group_root_dn
        expect(task.user_base_dn).to eq user_base_dn
        expect(task.user_scope).to eq user_scope
        expect(task.user_role_ids).to eq [ user_role.id ]
        expect(task.state).to eq "stop"
      end

      within ".gws-ldap-sync-task-admin" do
        click_on I18n.t("ldap.buttons.test_connection")
        expect(page).to have_css(".test-connection-result", text: "success")
      end

      within ".gws-ldap-sync-task-group" do
        click_on I18n.t("ldap.buttons.test_search")
        expect(page).to have_css(".group-test-search-result", text: "7#{I18n.t("ss.notice.hit")}")
      end

      within ".gws-ldap-sync-task-user" do
        click_on I18n.t("ldap.buttons.test_search")
        expect(page).to have_css(".user-test-search-result", text: "7#{I18n.t("ss.notice.hit")}")
      end
    end
  end

  context "no tasks are existed" do
    it_behaves_like "gws/ldap/sync/setting is"
  end

  context "task is existed" do
    let!(:task) { Gws::Ldap::SyncTask.where(group_id: site).reorder(id: 1).first_or_create }

    it_behaves_like "gws/ldap/sync/setting is"
  end
end
