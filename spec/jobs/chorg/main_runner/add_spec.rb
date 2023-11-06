require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with add" do
    let!(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset) { create(:add_changeset, revision_id: revision.id) }

    context "with all available attributes" do
      it do
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).count).to eq 1
        Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).first.tap do |group|
          destination0 = changeset.destinations[0]
          expect(group.name).to eq destination0["name"]
          expect(group.order).to eq destination0["order"].to_i
          expect(group.ldap_dn).to eq destination0["ldap_dn"]
          expect(group.contact_groups).to have(1).items
          group.contact_groups.first.tap do |contact_group|
            contact0 = destination0["contact_groups"][0]
            expect(contact_group.main_state).to eq contact0["main_state"]
            expect(contact_group.name).to eq contact0["name"]
            expect(contact_group.contact_group_name).to eq contact0["contact_group_name"]
            expect(contact_group.contact_charge).to eq contact0["contact_charge"]
            expect(contact_group.contact_tel).to eq contact0["contact_tel"]
            expect(contact_group.contact_fax).to eq contact0["contact_fax"]
            expect(contact_group.contact_email).to eq contact0["contact_email"]
            expect(contact_group.contact_link_url).to eq contact0["contact_link_url"]
            expect(contact_group.contact_link_name).to eq contact0["contact_link_name"]
          end
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
      end
    end

    context "with only name" do
      before do
        changeset.update!(destinations: [ { "name" => changeset.destinations[0]["name"] }.with_indifferent_access ])
      end

      it do
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).count).to eq 1
        Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).first.tap do |group|
          destination0 = changeset.destinations[0]
          expect(group.name).to eq destination0["name"]
          expect(group.order).to be_blank
          expect(group.ldap_dn).to be_blank
          expect(group.contact_groups).to be_blank
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
      end
    end

    context "without contact's name (this is required)" do
      before do
        destinations = changeset.destinations.dup
        destinations.each do |destination|
          destination["contact_groups"] << destination["contact_groups"][0].dup
          destination["contact_groups"][0].delete("name")
          destination["contact_groups"][1].delete("main_state")
          destination["contact_groups"][1].delete("name")
        end
        changeset.destinations = destinations
        changeset.save!(validate: false)
      end

      it do
        job = described_class.bind(site_id: site.id, task_id: task.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).count).to eq 1
        Cms::Group.all.where(name: /^#{Regexp.escape("#{root_group.name}/")}/).first.tap do |group|
          destination0 = changeset.destinations[0]
          expect(group.name).to eq destination0["name"]
          expect(group.order).to eq destination0["order"].to_i
          expect(group.ldap_dn).to eq destination0["ldap_dn"]
          expect(group.contact_groups).to have(2).items
          group.contact_groups[0].tap do |contact_group|
            contact0 = destination0["contact_groups"][0]
            expect(contact0["name"]).to be_blank

            expect(contact_group.main_state).to eq contact0["main_state"]
            expect(contact_group.name).to eq "main"
            expect(contact_group.contact_group_name).to eq contact0["contact_group_name"]
            expect(contact_group.contact_charge).to eq contact0["contact_charge"]
            expect(contact_group.contact_tel).to eq contact0["contact_tel"]
            expect(contact_group.contact_fax).to eq contact0["contact_fax"]
            expect(contact_group.contact_email).to eq contact0["contact_email"]
            expect(contact_group.contact_link_url).to eq contact0["contact_link_url"]
            expect(contact_group.contact_link_name).to eq contact0["contact_link_name"]
          end
          group.contact_groups[1].tap do |contact_group|
            contact1 = destination0["contact_groups"][1]
            expect(contact1["main_state"]).to be_blank
            expect(contact1["name"]).to be_blank

            expect(contact_group.main_state).to be_blank
            expect(contact_group.name).to eq "#{group.trailing_name}-1"
            expect(contact_group.contact_group_name).to eq contact1["contact_group_name"]
            expect(contact_group.contact_charge).to eq contact1["contact_charge"]
            expect(contact_group.contact_tel).to eq contact1["contact_tel"]
            expect(contact_group.contact_fax).to eq contact1["contact_fax"]
            expect(contact_group.contact_email).to eq contact1["contact_email"]
            expect(contact_group.contact_link_url).to eq contact1["contact_link_url"]
            expect(contact_group.contact_link_name).to eq contact1["contact_link_name"]
          end
        end

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
      end
    end
  end
end
