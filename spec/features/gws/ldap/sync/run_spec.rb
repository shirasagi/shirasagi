require 'spec_helper'

describe "gws_ldap_sync_run", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:role) { create :gws_role, cur_site: site }
  let!(:task) { Gws::Ldap::SyncTask.site(site).first_or_create }

  before do
    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    task.admin_dn = "cn=admin,dc=example,dc=jp"
    task.admin_password = SS::Crypto.encrypt("admin")

    task.group_base_dn = "dc=example,dc=jp"
    task.group_scope = "whole_subtree"
    task.group_filter = "(objectClass=ssGroup)"
    task.group_root_dn = "cn=シラサギ市, ou=Users, dc=shirasagi-city, dc=example, dc=jp"

    task.user_base_dn = "dc=example,dc=jp"
    task.user_scope = "whole_subtree"
    task.user_filter = "(objectClass=ssUser)"
    task.user_role_ids = [ role.id ]
    task.save!

    login_user user
  end

  it do
    visit gws_ldap_sync_run_path(site: site)
    within "form#task-form" do
      click_on I18n.t("ss.buttons.run")
    end
    wait_for_notice I18n.t("ss.tasks.started")

    expect(enqueued_jobs.size).to eq 1
    enqueued_jobs.first.tap do |enqueued_job|
      expect(enqueued_job[:job]).to eq Gws::Ldap::SyncJob
      expect(enqueued_job[:args]).to be_blank
    end

    expect(Gws::Ldap::SyncTask.all.count).to eq 1
    Gws::Ldap::SyncTask.find(task.id).tap do |after_task|
      expect(after_task.state).to eq "ready"
    end
    expect(page).to have_css(".task-box .state", text: I18n.t("job.state.ready"))
  end
end
