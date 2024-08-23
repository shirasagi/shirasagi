require 'spec_helper'

describe Tasks::Gws::Ldap, dbscope: :example, ldap: true do
  let!(:site) { gws_site }
  let!(:role) { create :gws_role, cur_site: site }
  let!(:task) { Gws::Ldap::SyncTask.site(site).first_or_create }

  before do
    @save = {}
    ENV.each do |key, value|
      @save[key.dup] = value.dup
    end

    SS::LdapSupport.ldap_add Rails.root.join("spec/fixtures/ldap/shirasagi2.ldif")

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
  end

  after do
    ENV.clear
    @save.each do |key, value|
      ENV[key] = value
    end

    SS::LdapSupport.stop_ldap_service
  end

  describe ".sync" do
    context "with specific site" do
      before do
        ENV['site'] = site.name
      end

      it do
        expect { described_class.sync }.to output(include(site.name)).to_stdout

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.class_name).to eq "Gws::Ldap::SyncJob"
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(::Gws::Ldap::SyncTask.all.count).to eq 1
        ::Gws::Ldap::SyncTask.find(task.id).tap do |after_task|
          expect(after_task.state).to eq "completed"
        end
      end
    end

    context "without site specifications" do
      it do
        expect { described_class.sync }.to output(include(site.name)).to_stdout

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.class_name).to eq "Gws::Ldap::SyncJob"
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(::Gws::Ldap::SyncTask.all.count).to eq 1
        ::Gws::Ldap::SyncTask.find(task.id).tap do |after_task|
          expect(after_task.state).to eq "completed"
        end
      end
    end
  end
end
