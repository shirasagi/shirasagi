require 'spec_helper'

describe Gws::Ldap::SyncJob, dbscope: :example, ldap: true do
  let!(:site) { create :gws_group }
  let!(:task) { Gws::Ldap::SyncTask.site(site).first_or_create }
  let(:now) { Time.zone.now.beginning_of_minute }

  before do
    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    task.admin_dn = "cn=admin,dc=example,dc=jp"
    task.admin_password = SS::Crypto.encrypt("admin")
    task.group_base_dn = "dc=example,dc=jp"
    task.group_scope = "whole_subtree"
    task.group_filter = <<~LDAP_FILTER
      (&
        (&
          (|
            (objectClass=organization)
            (objectClass=organizationalUnit)
          )
          (!(ou=Group))
        )
        (!(ou=People))
      )
    LDAP_FILTER
    task.user_base_dn = "dc=example,dc=jp"
    task.user_scope = "whole_subtree"
    task.user_filter = "(objectClass=inetOrgPerson)"
    task.save!
  end

  it do
    ss_perform_now described_class.bind(site_id: site, task_id: task)

    expect(Job::Log.all.count).to eq 1
    Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    expect(Gws::Group.all.site(site).count).to eq 7
    expect(Gws::User.all.site(site).count).to eq 7
  end
end
