require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy role" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:role) { cms_user.cms_roles.first }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ''
      task.save!
    end

    describe "copy cms/role" do
      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).not_to include(include('WARN'))
          expect(log.logs).not_to include(include('ERROR'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_role = Cms::Role.site(dest_site).find_by(name: role.name)
        expect(dest_role.name).to eq role.name
        expect(dest_role.permissions).to eq role.permissions
      end
    end

    describe "copy cms/role with permission_level" do
      before do
        # role.set(permission_level: 3)
        role.collection.update_one({ _id: role.id }, { '$set' => { permission_level: 3 } })

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).not_to include(include('WARN'))
          expect(log.logs).not_to include(include('ERROR'))
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_role = Cms::Role.site(dest_site).find_by(name: role.name)
        expect(dest_role.name).to eq role.name
        expect(dest_role.permissions).to eq role.permissions
      end
    end
  end
end
